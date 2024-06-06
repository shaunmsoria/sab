defmodule Compute do
  def get_all_pairs(factory_address, n_pair) do
    DexContract.all_pairs(n_pair)
    |> Ethers.call(to: factory_address)
  end

  def get_all_pairs_length(factory_address) do
    DexContract.all_pairs_length()
    |> Ethers.call(to: factory_address)
  end

  def get_pair_address(factory_address, token0_address, token1_address) do
    DexContract.get_pair(token0_address, token1_address)
    |> Ethers.call(to: factory_address)
  end

  defmacro contract(pair_address, function_contract) do
    quote do
      LiquidityPoolContract.unquote(function_contract)()
      |> Ethers.call(to: unquote(pair_address))
    end
  end

  defmacro contract(pair_address, function_contract, params) do
    quote do
      LiquidityPoolContract.unquote(function_contract)(unquote(params))
      |> Ethers.call(to: unquote(pair_address))
    end
  end

  defmacro contract_logs(pair_address, function_contract) do
    quote do
      LiquidityPoolContract.unquote(function_contract)()
      |> Ethers.get_logs(to: unquote(pair_address))
    end
  end



  def calculate_price(pair_address),
    do: calculate_price(pair_address, :O_I)
  def calculate_price(pair_address, :O_I) do
    with {:ok, [amount_0, amount_1, _time_stamp]} <-
      pair_address |> contract(:get_reserves) do
      amount_0 / amount_1
    end
  end

  def calculate_price(pair_address, :I_O) do
    with {:ok, [amount_0, amount_1, _time_stamp]} <-
      pair_address |> contract(:get_reserves) do
      amount_1 / amount_0
    end
  end

  def calculate_difference(price_0, price_1) do
    price_0 - price_1
  end

  def simulate_amount_output(factory_address, amount_in, reserve0, reserve1) do
    LiquidityPoolRouterContract.get_amount_out(amount_in, reserve0, reserve1)
    |> Ethers.call(to: factory_address)
  end

  def get_wallet_balance() do
    wallet_address = System.get_env("ACCOUNT_NUMBER")

    Ethers.Contracts.ERC20.balance_of("0x2170Ed0880ac9A755fd29B2688956BD959F933F8")
    |> Ethers.call(to: wallet_address)


  end


end
