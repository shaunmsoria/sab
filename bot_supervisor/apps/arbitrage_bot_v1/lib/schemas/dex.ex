defmodule Dex do
  defstruct name: "", version: "", router: "", factory: "", subgraph_url: "", subgraph_api_key: "", subgraph_id: "", subgraph_query: "{pairs {id token0 {id symbol} token1 {id symbol}}}"
end
