# MDExVideoEmbed

[![Hex.pm][shield-hex]][hexpm] [![Hex Docs][shield-docs]][docs]
[![Apache 2.0][shield-licence]][licence] ![Coveralls][shield-coveralls]

- code :: <https://github.com/halostatue/mdex_video_embed>
- issues :: <https://github.com/halostatue/mdex_video_embed/issues>
- examples :: <https://github.com/halostatue/mdex_video_embed/tree/main/example>

Privacy-respecting video embeds in Markdown with [MDEx][mdex] using a code
block.

Currently supporting YouTube embeds with click-to-load consent and
privacy-enhanced modes. Local mode provides maximum privacy (no `iframe` until
consent) but may require two clicks when browser auto-play policies apply.
[EmbedLite](https://embedlite.com) mode directly embeds `iframe` for
single-click playback.

See the [MDEx plugins guide][mdex-plugins] for more information on using MDEx
plugins.

## Privacy-First Design

This extension will only support video embeds where enhanced privacy options
exist.

- Privacy-enhanced embed modes
- Deferred user tracking until after consent provided
- Minimal data collection practices

Native support will not be provided for embeds with invasive tracking or
surveillance features.

## Quick Start

````elixir
markdown = """
```video source=youtube
dQw4w9WgXcQ
title=Never Gonna Give You Up
```
"""

MDEx.to_html!(markdown, plugins: [MDExVideoEmbed])
````

## Installation

Add `mdex_video_embed` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mdex_video_embed, "~> 1.0"}
  ]
end
```

Documentation is found on [HexDocs][docs].

## Semantic Versioning

MDExVideoEmbed follows [Semantic Versioning 2.0][semver].

[docs]: https://hexdocs.pm/mdex_video_embed
[hexpm]: https://hex.pm/packages/mdex_video_embed
[licence]: https://github.com/halostatue/mdex_video_embed/blob/main/LICENCE.md
[mdex-plugins]: https://hexdocs.pm/mdex/plugins.html
[mdex]: https://hexdocs.pm/mdex/
[semver]: https://semver.org/
[shield-coveralls]: https://img.shields.io/coverallsCoverage/github/halostatue/mdex_video_embed?style=flat-square
[shield-docs]: https://img.shields.io/badge/hex-docs-purple.svg?style=flat-square
[shield-hex]: https://img.shields.io/hexpm/v/mdex_video_embed.svg?style=flat-square
[shield-licence]: https://img.shields.io/hexpm/l/mdex_video_embed.svg?style=flat-square
