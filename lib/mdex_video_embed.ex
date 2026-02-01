defmodule MDExVideoEmbed do
  @moduledoc """
  Privacy-respecting video embed plugin for [MDEx][1].

  [1]: https://hexdocs.pm/mdex/

  Transforms markdown code blocks tagged as `video-embed` into privacy-friendly video
  embeds. Support will be provided only for video services with privacy-respecting embed
  options.

  See the [MDEx plugins guide][2] for more information on using MDEx plugins.

  [2]: https://hexdocs.pm/mdex/plugins.html

  Currently supported services:

  - YouTube (via `youtube-nocookie.com`)

  ## Configuration

  ```elixir
  MDEx.to_html!(markdown,
    plugins: [
      {MDExVideoEmbed, youtube: %{consent_message: "See our [privacy policy](/privacy)"}}
    ]
  )
  ```

  ## Usage Examples

  ### Basic Usage

  Basic video embed with default settings:

  ````elixir
  markdown = \"\"\"
  Check out this video:

  ```video-embed source=youtube
  dQw4w9WgXcQ
  title=Never Gonna Give You Up
  ```
  \"\"\"

  MDEx.to_html!(markdown, plugins: [MDExVideoEmbed])
  ````

  ### Provider-Specific Configuration

  Each provider may support different modes and options. For YouTube:

  ```elixir
  # YouTube with custom consent message
  MDEx.to_html!(markdown,
    plugins: [{MDExVideoEmbed, youtube: %{
      consent_message: "See our [privacy policy](/privacy)"
    }}]
  )

  # YouTube using embedlite.com service
  MDEx.to_html!(markdown,
    plugins: [{MDExVideoEmbed, youtube: %{provider: :embedlite}}]
  )
  ```

  ### Video Parameters

  Control playback behavior with parameters (support varies by provider):

  ````elixir
  markdown = \"\"\"
  ```video-embed source=youtube
  dQw4w9WgXcQ
  title=Rick Astley - Never Gonna Give You Up
  start=30
  end=120
  mute=true
  loop=true
  ```
  \"\"\"

  MDEx.to_html!(markdown, plugins: [MDExVideoEmbed])
  ````

  ## Code Block Syntax

  ````markdown
  ```video-embed source=youtube
  VIDEO_ID
  title=My Video Title
  start=30
  end=120
  ```
  ````

  - First line: `source=PROVIDER` (required)
  - Second line: video ID (required)
  - Subsequent lines: `key=value` parameters (optional)

  ## Configuration Options

  Configuration is provider-specific. Each provider is configured via a map keyed by the
  provider name (e.g., `:youtube`).

  See individual provider modules for their specific configuration options:

  - `MDExVideoEmbed.YouTube`

  ## Supported Parameters

  Parameters are provider-specific. Check individual provider documentation for supported
  parameters.

  ## Output Formats

  The plugin transforms video code blocks into HTML during document processing. This
  affects different MDEx output formats:

  - `to_html!/2` - Produces the intended video embed HTML
  - `to_heex!/2` - HTML blocks pass through to HEEx templates
  - `to_json!/2` - Serializes HTML blocks as `html_block` nodes in the AST
  - `to_xml!/2` - Converts HTML blocks to `<html_block>` XML elements
  - `to_markdown!/2` - Outputs raw HTML (original code block syntax is lost)
  - `to_delta!/2` - May not handle HTML blocks correctly for Quill Delta format

  If you need to preserve the original code block syntax for round-trip markdown
  conversion, don't attach the plugin to the document.

  ## Provider Requirements

  Different providers may have different requirements for JavaScript, CSS, or other
  resources. Check the provider-specific documentation for details.

  See `MDExVideoEmbed.YouTube` for YouTube-specific requirements.

  ## Integration with Tableau

  Example integration with Tableau static site generator:

  ```elixir
  # config/config.exs
  config :tableau, :config,
    markdown: [
      mdex: [
        plugins: [
          {MDExVideoEmbed, youtube: %{consent_message: "View our [privacy policy](/privacy)"}}
        ]
      ]
    ]
  ```

  Or with default settings:

  ```elixir
  config :tableau, :config,
    markdown: [mdex: [plugins: [MDExVideoEmbed]]]
  ```
  """

  alias MDEx.Document
  alias MDExVideoEmbed.YouTube

  @providers %{
    "youtube" => YouTube
  }

  @doc """
  Attaches the MDExVideoEmbed plugin into the MDEx document.

  ## Options

  Provider-specific configuration maps keyed by provider name:

  - `:youtube` - YouTube-specific configuration. See `m:MDExVideoEmbed.YouTube`.

  ## Examples

  ```elixir
  MDEx.to_html!(markdown, plugins: [MDExVideoEmbed])

  MDEx.to_html!(markdown,
    plugins: [{MDExVideoEmbed, youtube: %{provider: :embedlite}}]
  )

  MDEx.new(markdown: markdown)
  |> MDExVideoEmbed.attach()
  |> MDEx.to_html!()

  MDEx.new(markdown: markdown)
  |> MDExVideoEmbed.attach(
    youtube: %{
      provider: :local,
      consent_message: "See our [privacy policy](/privacy) before viewing."
    }
  )
  |> MDEx.to_html!()
  ```
  """
  @spec attach(Document.t(), keyword()) :: Document.t()
  def attach(document, options \\ []) do
    case validate_provider_options(options) do
      {:ok, validated_options} ->
        document
        |> Document.register_options([:video_embed_options])
        |> Document.put_options(video_embed_options: validated_options)
        |> Document.append_steps(enable_unsafe: &enable_unsafe/1)
        |> Document.append_steps(update_code_blocks: &update_code_blocks/1)
        |> Document.append_steps(inject_resources: &inject_resources/1)

      {:error, {provider, reason}} ->
        raise ArgumentError,
              "Invalid configuration for #{provider}: #{inspect(reason)}"
    end
  end

  @doc false
  def replace_text_params(text, params) do
    Enum.reduce(params, text, fn {key, value}, acc ->
      String.replace(acc, ~r/\{\{\s*#{Regex.escape(key)}\s*\}\}/, to_string(value))
    end)
  end

  @doc false
  def render_markdown_fragment(text) do
    text
    |> MDEx.to_html!()
    |> String.trim()
  end

  # Parses a video code block into a `{video_id, map()}` result.
  #
  # This is a helper function for internal providers. The first non-empty line becomes the
  # video ID value, and subsequent key=value lines are parsed into the map.
  #
  # Examples:
  #
  #   parse_video_block("""
  #   dQw4w9WgXcQ
  #   title=Test Video
  #   start=30
  #   """)
  #   #=> {:ok, %{video: "dQw4w9WgXcQ", "title" => "Test Video", "start" => "30"}}
  #
  #   parse_video_block("")
  #   #=> {:error, :empty_block}
  @doc false
  def parse_video_block(content) do
    lines =
      content
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case lines do
      [] ->
        {:error, :empty_block}

      [video | rest] ->
        {:ok, video, parse_rest_kv(rest)}
    end
  end

  defp validate_provider_options(options) do
    Enum.reduce_while(options, {:ok, %{}}, &validate_provider_options/2)
  end

  defp validate_provider_options({provider, opts}, {:ok, acc}) do
    provider = to_string(provider)

    case validate_provider_option(provider, opts) do
      {:ok, opts} -> {:cont, {:ok, Map.put(acc, provider, opts)}}
      :skip -> {:cont, {:ok, acc}}
      {:error, reason} -> {:halt, {:error, {provider, reason}}}
    end
  end

  defp validate_provider_option(provider, opts) do
    case get_provider_module(provider) do
      {:ok, provider_module} -> provider_module.config(opts)
      _ -> :skip
    end
  end

  defp enable_unsafe(document) do
    Document.put_render_options(document, unsafe: true)
  end

  defp update_code_blocks(document) do
    options = Document.get_option(document, :video_embed_options) || []

    {document, document_flags} =
      MDEx.traverse_and_update(document, %{}, fn
        %MDEx.CodeBlock{info: "video-embed " <> info, literal: content} = node, flags ->
          transform_video_block(node, info, content, options, flags)

        node, flags ->
          {node, flags}
      end)

    Document.put_private(document, :video_embed_flags, document_flags)
  end

  defp inject_resources(document) do
    document_flags = Document.get_private(document, :video_embed_flags, %{})

    Enum.reduce(document_flags, document, fn {provider_module, flags}, doc ->
      html = provider_module.document_html(flags)

      if html == "" do
        doc
      else
        Document.put_node_in_document_root(doc, %MDEx.HtmlBlock{literal: html}, :top)
      end
    end)
  end

  defp transform_video_block(node, info, content, options, flags) do
    with {:ok, source} <- parse_source(info),
         {:ok, provider_module} <- get_provider_module(source),
         provider_opts = get_provider_options(options, source),
         {:ok, html, provider_flags} <- provider_module.embed_html(content, provider_opts) do
      updated_flags = merge_provider_flags(flags, provider_module, provider_flags)
      {%MDEx.HtmlBlock{literal: html, nodes: node.nodes}, updated_flags}
    else
      _ ->
        {node, flags}
    end
  end

  defp parse_source(info) do
    case String.split(info, "=", parts: 2, trim: true) do
      ["source", source] -> {:ok, source}
      _ -> {:error, :invalid_source}
    end
  end

  defp get_provider_module(source), do: Map.fetch(@providers, source)

  defp get_provider_options(options, source), do: Map.get(options, source) || %{}

  # coveralls-ignore-next-line
  defp merge_provider_flags(flags, _provider_module, nil), do: flags

  defp merge_provider_flags(flags, provider_module, provider_flags) do
    Map.update(flags, provider_module, provider_flags, fn existing ->
      provider_module.merge_document_flags(existing, provider_flags)
    end)
  end

  defp parse_rest_kv(lines) do
    lines
    |> Enum.map(fn line ->
      case String.split(line, "=", parts: 2, trim: true) do
        [key, value] -> {key, value}
        [_single] -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end
end
