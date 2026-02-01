defmodule MDExVideoEmbed.Provider do
  @moduledoc """
  Behaviour for video embed providers.

  Providers implement this behaviour to support different video platforms with
  privacy-respecting embed options.
  """

  @doc """
  Validates and normalizes provider configuration.

  Called once when the plugin is attached to validate provider-specific options. Returns
  `{:ok, normalized_config}` or `{:error, reason}` where reason is a string.
  """
  @callback config(opts :: map()) :: {:ok, map()} | {:error, String.t()}

  @doc """
  Generates the HTML for embedding a video.

  The provider receives the raw block content and is responsible for parsing it.
  Providers may implement custom parsing for their specific format (e.g., JSON configuration,
  YAML, or simple key=value pairs).

  Returns `{:ok, html, document_flags}` where:

  - `html` is the embed HTML string
  - `document_flags` is a term (often `nil` or an atom) indicating whether document-level
    resources are needed

  Returns `{:error, reason}` if the video cannot be embedded.
  """
  @callback embed_html(content :: String.t(), opts :: map()) ::
              {:ok, html :: String.t(), document_flags :: term()} | {:error, term()}

  @doc """
  Merges document flags from multiple blocks.

  Called when processing multiple video blocks to combine their resource requirements.
  The provider determines how to merge flags - for example, boolean flags might use OR
  logic (once true, always true), while other providers might have different strategies.

  Returns the merged flags term.
  """
  @callback merge_document_flags(existing_flags :: term(), new_flags :: term()) :: term()

  @doc """
  Generates document-level HTML (scripts, styles) to inject into the page.

  Called once per provider with the merged document flags from all blocks. Returns an
  empty string if no document-level resources are needed.
  """
  @callback document_html(document_flags :: term()) :: String.t()
end
