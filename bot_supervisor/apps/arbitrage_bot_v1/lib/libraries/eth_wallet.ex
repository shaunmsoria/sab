defmodule EthWallet do
  alias W3WS.{Account, JSONRPC, Util}

  @provider Application.get_env(:w3ws, :default_url)

  def get_balance() do
    address = System.get_env("ACCOUNT_NUMBER")

    case JSONRPC.eth_get_balance(@provider, address) do
      {:ok, balance_wei} ->
        balance_eth = Util.from_wei(balance_wei)
        {:ok, balance_eth}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # def connect() do
  #   with  private_key <- System.get_env("PRIVATE_KEY"),
  #         address <- get_address_from_private_key(private_key),
  #         {:ok, balance} <- get_balance(address) do

  #   %{
  #     address: address,
  #     balance: balance
  #   }
  #   end
  # end

  # defp get_address_from_private_key(private_key) do
  #   {:ok, keypair} = Account.from_private_key(private_key)
  #   Account.to_address(keypair)
  # end

  # defp get_balance(address) do
  #   case JSONRPC.eth_get_balance(@provider, address) do
  #     {:ok, balance_wei} ->
  #       balance_eth = Util.from_wei(balance_wei)
  #       {:ok, balance_eth}
  #     {:error, reason} ->
  #       {:error, reason}
  #   end
  # end
end
