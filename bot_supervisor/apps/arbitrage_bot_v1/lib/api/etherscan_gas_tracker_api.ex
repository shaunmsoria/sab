defmodule EtherscanGasTrackerApi do
  use HTTPoison.Base

  @base_url "https://api.etherscan.io/api"
  @etherscan_api_key System.get_env("ETHERSCAN_API_KEY")


 defp process_url(module, action), do: "#{@base_url}?module=#{module}&action=#{action}&apikey=#{@etherscan_api_key}"

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

end
