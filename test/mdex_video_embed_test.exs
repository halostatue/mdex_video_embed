defmodule MDExVideoEmbedTest do
  use ExUnit.Case, async: true

  describe "attach/2" do
    test "accepts empty configuration" do
      assert get_video_embed_options() == %{}
    end

    test "validates known provider configuration" do
      assert %{"youtube" => _config} = get_video_embed_options(youtube: %{})
    end

    test "validates known provider configuration (invalid result)" do
      assert_raise ArgumentError,
                   ~r/Invalid configuration for youtube: "Configuration must be a map/,
                   fn ->
                     attach(youtube: :invalid)
                   end
    end

    test "skips unknown provider configuration" do
      options = get_video_embed_options(notatube: %{provider: :local})
      refute Map.has_key?(options, "notatube")
    end

    defp attach(options) do
      [markdown: "test"]
      |> MDEx.new()
      |> MDExVideoEmbed.attach(options)
    end

    defp get_video_embed_options(options \\ []) do
      options
      |> attach()
      |> MDEx.Document.get_option(:video_embed_options)
    end
  end

  describe "code block transformation" do
    test "transforms known provider blocks" do
      assert {:ok, html} = to_html("```video-embed source=youtube\ntest123\n```")

      assert html =~ "video-embed"
      refute html =~ "<code>"
    end

    test "leaves unknown provider blocks unchanged" do
      assert {:ok, html} = to_html("```video-embed source=notatube\ntest123\n```")

      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "leaves blank provider blocks unchanged" do
      assert {:ok, html} = to_html("```video-embed source=\ntest123\n```")

      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "leaves blocks without source parameter unchanged" do
      assert {:ok, html} = to_html("```video-embed\ntest123\n```")

      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "leaves blocks with invalid source parameters unchanged" do
      assert {:ok, html} = to_html("```video-embed src=xyz\ntest123\n```")
      assert html =~ "<code"
      refute html =~ "video-embed--"
    end

    test "processes multiple blocks independently" do
      assert {:ok, html} =
               to_html("""
               ```video-embed source=youtube
               first
               ```

               ```video-embed source=youtube
               second
               ```
               """)

      assert html =~ "first"
      assert html =~ "second"
      refute html =~ "<code>"
    end

    test "preserves surrounding markdown" do
      assert {:ok, html} =
               to_html("""
               # Heading

               ```video-embed source=youtube
               test123
               ```

               Paragraph.
               """)

      assert html =~ "<h1>Heading"
      assert html =~ "video-embed"
      assert html =~ "Paragraph"
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
