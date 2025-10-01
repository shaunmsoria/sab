defmodule EtherscanApi do
  use HTTPoison.Base

  @base_url "https://api.etherscan.io/v2/api"
  @etherscan_api_key System.get_env("ETHERSCAN_API_KEY")

  defp process_url(module, action),
    do: "#{@base_url}?chainid=1&module=#{module}&action=#{action}&apikey=#{@etherscan_api_key}"

  defp process_url(module, action, address),
    do:
      "#{@base_url}?chainid=1&module=#{module}&action=#{action}&contractaddress=#{address}&apikey=#{@etherscan_api_key}"

  def get_gas_oracle() do
    header = [{"Content-Type", "application/json"}]

    url = process_url("gastracker", "gasoracle")

    case get(url, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Error: #{reason}")
        {:error, reason}
    end
  end

  def get_tokens_of_token_pair(address) do
    header = [{"Content-Type", "application/json"}]

    url = process_url("account", "addresstokenbalance", address)

    case get(url, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Error: #{reason}")
        {:error, reason}
    end
  end
end
