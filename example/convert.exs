#!/usr/bin/env elixir

# Convert example markdown to HTML and serve with Bandit
# Usage: ./convert.exs

Mix.install([
  {:mdex, "~> 0.11"},
  {:mdex_video_embed, path: ".."},
  {:bandit, "~> 1.0"},
  {:plug, "~> 1.15"}
])

defmodule ExampleServer do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    md_files =
      "."
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".md"))
      |> Enum.sort()

    links =
      Enum.map_join(md_files, "\n", fn file -> "<li><a href=\"/#{file}\">#{file}</a></li>" end)

    html = html("<ul>#{links}</ul>")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  get "/:filename" do
    if String.ends_with?(filename, ".md") and File.exists?(filename) do
      render_markdown(conn, filename)
    else
      send_resp(conn, 404, "Not found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp render_markdown(conn, filename) do
    rendered =
      filename
      |> File.read!()
      |> MDEx.to_html!(plugins: [{MDExVideoEmbed, youtube: %{use_default_css: true}}])

    title = "#{filename} - MDExVideoEmbed Examples"

    html =
      html(
        """
          <p><a href="/">&larr; Back to examples</a></p>
        #{rendered}
        """,
        title: title
      )

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp html(body, options \\ []) do
    title = Keyword.get(options, :title, "MDExVideoEmbed Examples")

    """
    <!DOCTYPE html>
    <html lang="en">
    #{head(title)}
    #{body(body, title)}
    </html>
    """
  end

  defp head(title) do
    """
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{title}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 800px;
          margin: 40px auto;
          padding: 0 20px;
          line-height: 1.6;
        }
        h1 { color: #333; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
      </style>
    </head>
    """
  end

  defp body(body, title) do
    """
    <body>
      <h1>#{title}</h1>
      #{body}
    </body>
    """
  end
end

IO.puts("Starting server at http://localhost:4000")
IO.puts("Press Ctrl+C to stop")

Bandit.start_link(plug: ExampleServer, port: 4000)
Process.sleep(:infinity)
