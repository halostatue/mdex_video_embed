default_consent_message = """
This video is hosted on YouTube. By clicking **Play**, you consent to YouTube setting
cookies and loading external content.
"""

defmodule MDExVideoEmbed.YouTube do
  @moduledoc """
  YouTube video embed provider with privacy-respecting options.

  ## Provider Modes

  YouTube supports two provider modes with different trade-offs:

  | Feature              | Local Mode (`:local`)             | Embedlite Mode (`:embedlite`)  |
  | -------------------- | --------------------------------- | ------------------------------ |
  | Privacy              | Highest (no contact until click)  | High (delegated to embedlite)  |
  | GDPR Compliance      | Built-in consent messaging        | Handled by embedlite           |
  | JavaScript Required  | Yes (auto-injected)               | No                             |
  | Custom Consent       | Yes                               | No                             |
  | Initial Page Load    | Thumbnail only                    | Iframe loaded                  |
  | User Interaction     | Two clicks (consent + play)       | One click (play)               |

  These are selected with `mode: :local` or `mode: :embedlite`, respectively. These may be
  overridden on a case-by-case basis with the embed parameter `mode`.

  > #### Autoplay Behavior {: .info}
  >
  > Local mode may require two clicks when browser autoplay policies block automatic
  > playback. The iframe loads on first click, then user must click play in the YouTube
  > player. Embedlite mode can autoplay because the iframe is pre-loaded.

  ## Configuration Options

  - `:mode` (default `:local`): Embedding mode (`:local` or `:embedlite`). The
    `:embedlite` embedding mode uses [EmbedLite](https://embedlite.com) iframes.
  - `:consent_message`: Custom consent message for local mode. Treated as a markdown
    fragment with placeholder support.

    The default value is:

    > #{String.replace(default_consent_message, "\n", " ")}

  - `:use_default_css` (default `false`): Inject default CSS styles
  - `:button_text` (default: `"Play {{ title }}"`): Default button text for `:local`
    embedding mode. Treated as a markdown fragment with placeholder support.
  - `:button_aria_label` (default: `"Play video: {{ title }}"`): Default button aria-label
    for `:local` embedding mode. Supports placeholder replacement.

  > #### Markdown Fragment Processing {: .info}
  >
  > The `:consent_message` and `:button_text` options are processed as markdown fragments.
  > **Keep it simple**: use only inline elements like links, emphasis, and strong text.
  > Complex structures (tables, code blocks, nested lists) are not supported and may
  > render incorrectly.

  > #### Placeholder Replacement {: .info}
  >
  > The `:consent_message`, `:button_text`, and `:button_aria_label` options support
  > placeholder replacement. The only supported placeholder value is `title`, written
  > as `{{title}}` or `{{ title }}` (whitespace is ignored).

  ## Asset Dependencies

  ### JavaScript

  No additional JavaScript setup should be required with either embedding mode; `:local`
  embedding automatically injects click-to-load JavaScript functionality and `:embedlite`
  uses direct iframe embedding.

  ### CSS

  The `:local` mode requires CSS for proper display of the thumbnail, overlay, and button.
  You can either:

  1. Set `use_default_css: true` to automatically inject default styles
  2. Provide your own CSS in your stylesheet

  The default CSS is available in `priv/provider/youtube/default.css` and can be used as
  a starting point for custom styling.

  The `:embedlite` mode uses a default iframe and does not require additional CSS.

  ## Supported Parameters

  All parameters are optional.

  ### Mode Override

  - `mode`: Override configured provider mode (`local` or `embedlite`)

  ### Both Modes

  - `title`: Video title for accessibility and display
  - `autoplay` (default `false`): Allow autoplay (true/false)
  - `start`: Start time in seconds
  - `end`: End time in seconds
  - `mute`: Start muted (true/false)
  - `loop`: Loop video (true/false)
  - `controls` (default `show`): Show controls (`show`/`hide` or `1`/`0`)

  ### Local Embedding Mode Only

  - `button-text`: Button text override; treated as a markdown fragment with placeholder
    support.
  - `button-aria-label`: Button aria-label override with placeholder support.
  """

  @behaviour MDExVideoEmbed.Provider

  @default_consent_message default_consent_message
  click_to_load_js = Path.join([__DIR__, "../../priv/provider/youtube/click_to_load.js"])
  default_css_file = Path.join([__DIR__, "../../priv/provider/youtube/default.css"])

  @external_resource click_to_load_js
  @external_resource default_css_file

  @script_body "<script>" <> File.read!(click_to_load_js) <> "</script>"
  @style_body "<style>" <> File.read!(default_css_file) <> "</style>"

  @impl MDExVideoEmbed.Provider
  def config(opts) when is_map(opts) do
    mode = Map.get(opts, :mode, Map.get(opts, :provider, :local))
    consent_message = Map.get(opts, :consent_message, @default_consent_message)
    use_default_css = Map.get(opts, :use_default_css, false)
    button_text = Map.get(opts, :button_text, "Play {{ title }}")
    button_aria_label = Map.get(opts, :button_aria_label, "Play video: {{ title }}")

    if mode in [:local, :embedlite] do
      {:ok,
       %{
         mode: mode,
         consent_message: consent_message,
         use_default_css: use_default_css,
         button_text: button_text,
         button_aria_label: button_aria_label
       }}
    else
      {:error, "Invalid YouTube mode #{inspect(mode)} (allowed: [:local, :embedlite])"}
    end
  end

  def config(opts), do: {:error, "Configuration must be a map, got: #{inspect(opts)}"}

  @impl MDExVideoEmbed.Provider
  def embed_html(content, opts) do
    case MDExVideoEmbed.parse_video_block(content) do
      {:ok, video_id, params} ->
        mode = Map.get(params, "mode", Map.get(opts, :mode, :local))
        use_default_css = Map.get(opts, :use_default_css, false)

        cond do
          mode in [:local, "local"] ->
            html = build_local_embed(video_id, params, opts)
            {:ok, html, %{script: true, style: use_default_css}}

          mode in [:embedlite, "embedlite"] ->
            html = build_embedlite_embed(video_id, params)
            {:ok, html, %{style: use_default_css}}

          true ->
            {:error, :invalid_block}
        end

      _ ->
        {:error, :invalid_block}
    end
  end

  @impl MDExVideoEmbed.Provider
  def merge_document_flags(existing, new) do
    Map.merge(existing, new, fn
      key, true, _ when key in [:script, :style] -> true
      _key, _, new_val -> new_val
    end)
  end

  @impl MDExVideoEmbed.Provider
  def document_html(flags) do
    Enum.join([render_script(flags), render_style(flags)], "")
  end

  defp build_local_embed(video_id, params, opts) do
    title = normalize_title(params)
    replacements = %{"title" => title}

    button_text =
      params
      |> Map.get("button-text", Map.get(opts, :button_text, "Play {{ title }}"))
      |> MDExVideoEmbed.replace_text_params(replacements)
      |> MDExVideoEmbed.render_markdown_fragment()

    button_aria =
      params
      |> Map.get("button-aria-label", Map.get(opts, :button_aria_label, "Play video: {{ title }}"))
      |> MDExVideoEmbed.replace_text_params(replacements)

    autoplay = Map.get(params, "autoplay", "false")

    consent_message_html =
      opts
      |> Map.get(:consent_message, @default_consent_message)
      |> MDExVideoEmbed.replace_text_params(replacements)
      |> MDExVideoEmbed.render_markdown_fragment()

    query_string = build_query_string(params)
    data_params_attr = if query_string == "", do: "", else: ~s( data-video-embed-params="#{query_string}")
    data_allow_attr = if autoplay == "true", do: ~s( data-video-embed-allow="true"), else: ""

    """
    <div class="video-embed video-embed--youtube" data-video-embed-id="#{video_id}"#{data_params_attr}#{data_allow_attr}>
      <img class="video-embed__thumbnail" id="yt-thumb-#{video_id}"
           src="https://i.ytimg.com/vi/#{video_id}/sddefault.jpg"
           srcset="https://i.ytimg.com/vi/#{video_id}/sddefault.jpg 640w,
                   https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg 480w,
                   https://i.ytimg.com/vi/#{video_id}/mqdefault.jpg 320w,
                   https://i.ytimg.com/vi/#{video_id}/default.jpg 120w"
           sizes="(min-width: 640px) 640px, 100vw"
           alt="#{title}"
           loading="lazy">
      <div class="video-embed__overlay">
        <h3 class="video-embed__title">#{title}</h3>
        <div class="video-embed__consent">#{consent_message_html}</div>
        <button class="video-embed__show" aria-label="#{button_aria}">
          #{button_text}
        </button>
      </div>
    </div>
    """
  end

  defp build_embedlite_embed(video_id, params) do
    title = normalize_title(params)
    autoplay = Map.get(params, "autoplay", "false")

    query_string = build_query_string(params)
    query_string = if query_string == "", do: "", else: "?#{query_string}"

    allow_parts = ["encrypted-media", "picture-in-picture"]
    allow_parts = if autoplay == "true", do: allow_parts ++ ["autoplay"], else: allow_parts
    allow_attr = Enum.join(allow_parts, "; ")

    """
    <div class="video-embed video-embed--embedlite">
      <iframe src="https://embedlite.com/embed/#{video_id}#{query_string}"
              title="#{title}"
              frameborder="0"
              allow="#{allow_attr}"
              referrerpolicy="strict-origin-when-cross-origin"
              allowfullscreen
              loading="lazy">
      </iframe>
    </div>
    """
  end

  defp normalize_title(params) do
    case Map.get(params, "title", "") do
      "" -> "YouTube video"
      title -> title
    end
  end

  defp build_query_string(params) do
    params
    |> Map.drop(["title", "button-text", "button-aria-label", "autoplay"])
    |> normalize_params()
    |> Enum.map_join("&", fn {k, v} -> "#{k}=#{v}" end)
  end

  defp normalize_params(params) do
    Enum.map(params, fn
      {"controls", "show"} -> {"controls", "1"}
      {"controls", "hide"} -> {"controls", "0"}
      {k, v} -> {k, v}
    end)
  end

  defp render_script(%{script: true}), do: @script_body
  defp render_script(_), do: ""

  defp render_style(%{style: true}), do: @style_body
  defp render_style(_), do: ""
end
