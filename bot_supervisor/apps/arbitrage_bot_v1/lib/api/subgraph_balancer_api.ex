defmodule SubgraphBalancerApi do
  use HTTPoison.Base

  @balancer Libraries.balancer()

  def process_url(url, _opts) do
    url
  end

  def process_reponse_body(body, _opts) do
    {:ok, Jason.decode(body)}
  end

  def get_balancer_pool_ids() do
    header = [{"Content-Type", "application/json"}]
    body = Jason.encode!(%{"query" => @balancer["subgraph_query"]})

    url = @balancer["base_url"] <>  body

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
