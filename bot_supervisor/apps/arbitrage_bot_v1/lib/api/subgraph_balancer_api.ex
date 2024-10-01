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
    body = Jason.encode!(%{})
    |> LogWritter.ipt("sx1 body")

    url = @balancer["url"]

    response = post(url, body, header)
    |> LogWritter.ipt("sx1 Jason.decode(body) ")

    case response do
      {:ok,
       %{
         status_code: 200,
         body: body
       }} ->
        Jason.decode(body)

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
