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
    |> IO.inspect(label: "sx1 get_pair_address result")
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
        case {is_integer(amount_0), is_integer(amount_1)} do
          {true, true} -> amount_0 / amount_1
          {_, _} -> {:error, "calculate_price issue with amount_0 #{amount_0} or #{amount_1}"}
        end

        # amount_0 / amount_1


      else _ -> {:error, "no price found for the pair #{pair_address}"}
    end
  end

  def calculate_price(pair_address, :I_O) do

    with {:ok, [amount_0, amount_1, _time_stamp]} <-
      pair_address |> contract(:get_reserves) do
        case {is_integer(amount_0), is_integer(amount_1)} do
          {true, true} -> amount_1 / amount_0
          {_, _} -> {:error, "calculate_price issue with amount_0 #{amount_0} or #{amount_1}"}
        end

      # amount_1 / amount_0


      else _ -> {:error, "no price found for the pair #{pair_address}"}
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

    {:ok, eth_wallet_amount_wei} = Ethers.get_balance(wallet_address)

    {:ok, Ethers.Utils.from_wei(eth_wallet_amount_wei)}
  end

  def execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount, env \\ System.get_env("ENV"))

  def execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount, "prod") do
    IO.puts("sx1 in execute_trade prod")

    smart_contract_address = System.get_env("CONTRACT_ADDRESS")
    owner_wallet_address = System.get_env("ACCOUNT_NUMBER")

    # Sabv1Contract.execute_trade(token0_address, token1_address, router_address, router_address_searched, 10000000000000)
    Sabv1Contract.execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount)
    |> Ethers.call(to: smart_contract_address)
    # |> Ethers.call(from: owner_wallet_address, to: smart_contract_address)
  end


  def execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount, "dev") do
    IO.puts("sx1 in execute_trade dev")

    smart_contract_address = System.get_env("SEPOLIA_CONTRACT_ADDRESS")
    owner_wallet_address = System.get_env("SEPOLIA_ACCOUNT_NUMBER")

    Sabv1Contract.execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount)
    # Sabv1Contract.execute_trade(token0_address, token1_address, router_address, router_address_searched, tradable_amount)
    |> IO.inspect(label: "mx1 execute_trade pre Ethers.call result")
    |> Ethers.call(to: smart_contract_address)
    |> IO.inspect(label: "mx1 execute_trade result")
    # |> Ethers.call(from: owner_wallet_address, to: smart_contract_address)
  end

  def test_smart_contract() do
    smart_contract_address = System.get_env("CONTRACT_ADDRESS")

    Sabv1Contract.get_string()
    |> Ethers.call(to: smart_contract_address)
  end


end
