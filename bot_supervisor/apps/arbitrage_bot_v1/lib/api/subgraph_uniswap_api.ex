defmodule SubgraphUniswapApi do
  use HTTPoison.Base

  # @base_url "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2"

  def process_url(url, _opts) do
    url
  end

  def process_reponse_body(body, _opts) do
    {:ok, Jason.decode(body)}
  end

  def get_liquidity_pool_pairs(%Dex{} = dex) do
    header = [{"Content-Type", "application/json"}]
    body = Jason.encode!(%{"query" => dex.subgraph_query})

    url = dex.subgraph_url <> "/" <> dex.subgraph_api_key <> "/subgraphs/id/" <> dex.subgraph_id

    response = post(url, body, header)

    case response do
      {:ok,
       %{
         status_code: 200,
         body: body
       }} ->
        Jason.decode(body)

      # |> IO.inspect(label: "sx1 Jason.decode(body) ")
      {:ok,
       %{
         status_code: code,
         body: _body
       }} ->
        {:error, "status_code: #{code}"}

      _ ->
        {:error, "subgraph error"}
    end
  end
end
