defmodule MDExVideoEmbed.YouTubeTest do
  use ExUnit.Case, async: true

  describe "config/1" do
    test "accepts :local provider" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{mode: :local})
      assert config.mode == :local
    end

    test "accepts :embedlite provider" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{mode: :embedlite})
      assert config.mode == :embedlite
    end

    test "defaults to :local provider" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{})
      assert config.mode == :local
    end

    test "defaults use_default_css to false" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{})
      assert config.use_default_css == false
    end

    test "accepts use_default_css option" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{use_default_css: true})
      assert config.use_default_css == true
    end

    test "accepts custom consent_message" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{consent_message: "Custom"})
      assert config.consent_message == "Custom"
    end

    test "accepts custom button_text" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{button_text: "Watch Now"})
      assert config.button_text == "Watch Now"
    end

    test "accepts custom button_aria_label" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{button_aria_label: "Start video"})
      assert config.button_aria_label == "Start video"
    end

    test "defaults button_text to 'Play {{ title }}'" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{})
      assert config.button_text == "Play {{ title }}"
    end

    test "defaults button_aria_label to 'Play video: {{ title }}'" do
      assert {:ok, config} = MDExVideoEmbed.YouTube.config(%{})
      assert config.button_aria_label == "Play video: {{ title }}"
    end

    test "rejects invalid provider mode" do
      assert {:error, reason} = MDExVideoEmbed.YouTube.config(%{mode: :invalid})
      assert is_binary(reason)
    end

    test "rejects invalid config type" do
      assert {:error, reason} = MDExVideoEmbed.YouTube.config("not a map")
      assert is_binary(reason)
    end
  end

  describe "local mode rendering" do
    test "generates placeholder with thumbnail and button" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ "video-embed--youtube"
      assert html =~ "video-embed__thumbnail"
      assert html =~ "video-embed__show"
      assert html =~ "Play"
      refute html =~ "<iframe"
    end

    test "includes consent message" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ "video-embed__consent"
      assert html =~ "video-embed__overlay"
    end

    test "renders custom consent message as markdown" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{consent_message: "See [privacy](/privacy)."}
               )

      assert html =~ ~s(<a href="/privacy">privacy</a>)
    end

    test "supports {{ title }} placeholder in consent message" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 title=My Video
                 ```
                 """,
                 youtube: %{consent_message: "Watch **{{ title }}** on YouTube."}
               )

      assert html =~ "Watch <strong>My Video</strong> on YouTube."
    end

    test "uses title in alt text and aria-label" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               title=Test Video
               ```
               """)

      assert html =~ ~s(alt="Test Video")
      assert html =~ ~s(aria-label="Play video: Test Video")
    end

    test "defaults to 'YouTube video' when title missing" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ ~s(alt="YouTube video")
      assert html =~ ~s(aria-label="Play video: YouTube video")
    end

    test "defaults to 'YouTube video' when title blank" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               title=
               ```
               """)

      assert html =~ ~s(alt="YouTube video")
      assert html =~ ~s(aria-label="Play video: YouTube video")
    end

    test "includes thumbnail with srcset" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ "i.ytimg.com/vi/test123/sddefault.jpg 640w"
      assert html =~ "i.ytimg.com/vi/test123/hqdefault.jpg 480w"
      assert html =~ "i.ytimg.com/vi/test123/mqdefault.jpg 320w"
      assert html =~ "i.ytimg.com/vi/test123/default.jpg 120w"
      assert html =~ ~s(loading="lazy")
    end

    test "stores parameters in data-video-embed-params" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               start=30
               end=60
               ```
               """)

      assert html =~ "start=30"
      assert html =~ "end=60"
      assert html =~ "data-video-embed-params="
    end

    test "excludes title from data-video-embed-params" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               title=Test
               start=30
               ```
               """)

      assert html =~ "start=30"
      refute html =~ ~r/data-video-embed-params="[^"]*title/
    end

    test "excludes autoplay from data-video-embed-params" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               autoplay=true
               start=30
               ```
               """)

      assert html =~ "start=30"
      refute html =~ ~r/data-video-embed-params="[^"]*autoplay/
    end

    test "excludes button-text from data-video-embed-params" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               button-text=Click Me
               start=30
               ```
               """)

      assert html =~ "start=30"
      refute html =~ ~r/data-video-embed-params="[^"]*button-text/
    end

    test "excludes button-aria-label from data-video-embed-params" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               button-aria-label=Custom Label
               start=30
               ```
               """)

      assert html =~ "start=30"
      refute html =~ ~r/data-video-embed-params="[^"]*button-aria-label/
    end

    test "adds data-video-embed-allow when autoplay=true" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               autoplay=true
               ```
               """)

      assert html =~ ~s(data-video-embed-allow="true")
    end

    test "omits data-video-embed-allow when autoplay=false" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               autoplay=false
               ```
               """)

      refute html =~ "data-video-embed-allow"
    end

    test "converts controls=hide to controls=0" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               controls=hide
               ```
               """)

      assert html =~ "controls=0"
    end

    test "converts controls=show to controls=1" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               controls=show
               ```
               """)

      assert html =~ "controls=1"
    end

    test "preserves numeric controls values" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               controls=0
               ```
               """)

      assert html =~ "controls=0"
    end

    test "injects script by default" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ "<script>"
      assert html =~ "video-embed__show"
    end

    test "injects CSS when use_default_css is true" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{use_default_css: true}
               )

      assert html =~ "<style>"
      assert html =~ ".video-embed"
    end

    test "does not inject CSS when use_default_css is false" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      refute html =~ "<style>"
    end
  end

  describe "embedlite mode rendering" do
    test "generates iframe embed" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{mode: :embedlite}
               )

      assert html =~ "video-embed--embedlite"
      assert html =~ "<iframe"
      assert html =~ "embedlite.com/embed/test123"
      refute html =~ "video-embed__thumbnail"
      refute html =~ "video-embed__consent"
    end

    test "includes required allow attributes" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{mode: :embedlite}
               )

      assert html =~ ~s(allow=")
      assert html =~ "encrypted-media"
      assert html =~ "picture-in-picture"
    end

    test "excludes forbidden allow attributes" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{mode: :embedlite}
               )

      refute html =~ "accelerometer"
      refute html =~ "gyroscope"
    end

    test "includes autoplay in allow when autoplay=true" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 autoplay=true
                 ```
                 """,
                 youtube: %{mode: :embedlite}
               )

      assert html =~ ~r/allow="[^"]*autoplay/
    end

    test "excludes autoplay from allow when autoplay=false" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 autoplay=false
                 ```
                 """,
                 youtube: %{mode: :embedlite}
               )

      refute html =~ ~r/allow="[^"]*autoplay/
    end

    test "includes parameters in iframe src query string" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 start=30
                 end=60
                 ```
                 """,
                 youtube: %{mode: :embedlite}
               )

      assert html =~ "embedlite.com/embed/test123?"
      assert html =~ "start=30"
      assert html =~ "end=60"
    end

    test "uses title in iframe title attribute" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 title=Test Video
                 ```
                 """,
                 youtube: %{mode: :embedlite}
               )

      assert html =~ ~s(title="Test Video")
    end

    test "injects CSS when use_default_css is true" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{mode: :embedlite, use_default_css: true}
               )

      assert html =~ "<style>"
      refute html =~ "<script>"
    end

    test "injects nothing when use_default_css is false" do
      assert {:ok, html} =
               to_html(
                 "```video-embed source=youtube\ntest123\n```",
                 youtube: %{mode: :embedlite, use_default_css: false}
               )

      refute html =~ "<style>"
      refute html =~ "<script>"
    end
  end

  describe "edge cases" do
    test "handles empty video block" do
      assert {:ok, html} = to_html("```video-embed source=youtube\n```")

      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "supports {{ title }} placeholder in button-text" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               title=My Video
               button-text=Watch {{ title }} Now
               ```
               """)

      assert html =~ "Watch My Video Now"
    end

    test "supports {{ title }} placeholder in button-aria-label" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               title=My Video
               button-aria-label=Click to play {{ title }}
               ```
               """)

      assert html =~ ~s(aria-label="Click to play My Video")
    end

    test "uses config button_text default" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 title=My Video
                 ```
                 """,
                 youtube: %{button_text: "Watch {{ title }}"}
               )

      assert html =~ "Watch My Video"
    end

    test "uses config button_aria_label default" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 title=My Video
                 ```
                 """,
                 youtube: %{button_aria_label: "Start {{ title }}"}
               )

      assert html =~ ~s(aria-label="Start My Video")
    end

    test "parameter overrides config button_text" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 title=My Video
                 button-text=Override
                 ```
                 """,
                 youtube: %{button_text: "Config Default"}
               )

      assert html =~ "Override"
      refute html =~ "Config Default"
    end

    test "extracts video ID with leading whitespace" do
      assert {:ok, html} = to_html("```video-embed source=youtube\n  test123\n```")

      assert html =~ ~s(data-video-embed-id="test123")
    end

    test "extracts video ID with trailing whitespace" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123  \n```")

      assert html =~ ~s(data-video-embed-id="test123")
    end

    test "extracts video ID with leading empty lines" do
      assert {:ok, html} = to_html("```video-embed source=youtube\n\n\ntest123\n```")

      assert html =~ ~s(data-video-embed-id="test123")
    end
  end

  describe "mode parameter override" do
    test "ignores invalid mode parameter" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               test123
               mode=invalid
               ```
               """)

      # Should leave as code block since provider is invalid
      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "overrides config provider :local with mode=embedlite" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 mode=embedlite
                 ```
                 """,
                 youtube: %{mode: :local}
               )

      # Should use embedlite mode despite config saying local
      assert html =~ "video-embed--embedlite"
      assert html =~ "<iframe"
      refute html =~ "video-embed__thumbnail"
    end

    test "overrides config provider :embedlite with mode=local" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 test123
                 mode=local
                 ```
                 """,
                 youtube: %{mode: :embedlite}
               )

      # Should use local mode despite config saying embedlite
      assert html =~ "video-embed--youtube"
      assert html =~ "video-embed__thumbnail"
      refute html =~ "<iframe"
    end

    test "respects mode parameter order in document" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 first
                 mode=embedlite
                 ```

                 ```video-embed source=youtube
                 second
                 mode=local
                 ```
                 """,
                 youtube: %{mode: :local}
               )

      assert {embedlite_pos, _} = :binary.match(html, "embedlite.com/embed/first")
      assert {local_pos, _} = :binary.match(html, ~s(data-video-embed-id="second"))

      assert embedlite_pos < local_pos
    end

    test "merges flags across mixed modes - script stays true" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 first
                 mode=embedlite
                 ```

                 ```video-embed source=youtube
                 second
                 mode=local
                 ```

                 ```video-embed source=youtube
                 third
                 mode=embedlite
                 ```
                 """,
                 youtube: %{mode: :embedlite, use_default_css: false}
               )

      # Should inject script because local mode was used
      assert html =~ "<script>"
      # Should not inject CSS because use_default_css is false
      refute html =~ "<style>"
    end

    test "merges flags across mixed modes - css stays true" do
      assert {:ok, html} =
               to_html(
                 """
                 ```video-embed source=youtube
                 first
                 mode=embedlite
                 ```

                 ```video-embed source=youtube
                 second
                 mode=local
                 ```

                 ```video-embed source=youtube
                 third
                 mode=embedlite
                 ```
                 """,
                 youtube: %{mode: :embedlite, use_default_css: true}
               )

      # Should inject both script and CSS
      assert html =~ "<script>"
      assert html =~ "<style>"
    end
  end

  defp to_html(markdown, options \\ [])

  defp to_html(markdown, []) do
    MDEx.to_html(markdown, plugins: [MDExVideoEmbed])
  end

  defp to_html(markdown, options) do
    MDEx.to_html(markdown, plugins: [{MDExVideoEmbed, options}])
  end
end
