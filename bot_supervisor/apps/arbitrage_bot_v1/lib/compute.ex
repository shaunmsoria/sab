defmodule Compute do
  def get_all_pairs(factory_address, n_pair) do
    FactoryContractV2.all_pairs(n_pair)
    |> Ethers.call(to: factory_address)
  end

  def get_all_pairs_length(factory_address) do
    FactoryContractV2.all_pairs_length()
    |> Ethers.call(to: factory_address)
  end

  def get_pair_address(factory_address, token0_address, token1_address) do
    FactoryContractV2.get_pair(token0_address, token1_address)
    |> Ethers.call(to: factory_address)
  end

  def get_pool_address(factory_address, token0_address, token1_address, fee) do
    FactoryContractV3.get_pool(token0_address, token1_address, fee)
    |> Ethers.call(to: factory_address)
  end

  defmacro pool(pair_address, abi, function, params \\ nil) do
    case {abi, params} do
      {"uniswapV2", nil} ->
        quote do
          PoolContractV2.unquote(function)()
          |> Ethers.call(to: unquote(pair_address))
        end

      {"uniswapV2", params} ->
        quote do
          PoolContractV2.unquote(function)(unquote(params))
          |> Ethers.call(to: unquote(pair_address))
        end

      {"uniswapV3", nil} ->
        quote do
          PoolContractV3.unquote(function)()
          |> Ethers.call(to: unquote(pair_address))
        end

      {"uniswapV3", params} ->
        quote do
          PoolContractV3.unquote(function)(unquote(params))
          |> Ethers.call(to: unquote(pair_address))
        end
    end
  end

  defmacro token_erc20(token_address, function, params \\ nil) do
    case params do
      nil ->
        quote do
          TokenERC20Contract.unquote(function)()
          |> Ethers.call(to: unquote(token_address))
        end

      params ->
        quote do
          TokenERC20Contract.unquote(function)(unquote(params))
          |> Ethers.call(to: unquote(token_address))
        end
    end
  end

  def calculate_price(pair_address),
    do: calculate_price(pair_address, :O_I)

  def calulcate_price("", _), do: {:error, "no pair address extracted from event"}

  def calculate_price(pair_address, :O_I) do
    with {:ok, [amount_0, amount_1, _time_stamp]} <-
           pair_address |> pool("uniswapV2", :get_reserves) do
      case {is_integer(amount_0), is_integer(amount_1), amount_1 != 0} do
        {true, true, true} -> {:ok, amount_0 / amount_1, amount_0, amount_1}
        {true, true, false} -> {:ok, 0, amount_0, amount_1}
        {_, _} -> {:error, "calculate_price issue with amount_0 #{amount_0} or #{amount_1}"}
      end
    else
      _ -> {:error, "no price found for the pair #{pair_address}"}
    end
  end

  def calculate_price(pair_address, :I_O) do
    with {:ok, [amount_0, amount_1, _time_stamp]} <-
           pair_address |> pool("uniswapV2", :get_reserves) do
      case {is_integer(amount_0), is_integer(amount_1), amount_0 != 0} do
        {true, true, true} -> {:ok, amount_1 / amount_0, amount_0, amount_1}
        {true, true, false} -> {:ok, 0, amount_0, amount_1}
        {_, _} -> {:error, "calculate_price issue with amount_0 #{amount_0} or #{amount_1}"}
      end
    else
      _ -> {:error, "no price found for the pair #{pair_address}"}
    end
  end

  def calculate_difference(price_0, price_1) do
    with price_0_value <- String.to_float(price_0),
         price_1_value <- String.to_float(price_1) do
      price_0_value - price_1_value
    end
  end

  def simulate_amount_input(router_address, amount_in, reserve0, reserve1) do
    RouterContractV2.get_amount_in(amount_in, reserve0, reserve1)
    |> Ethers.call(to: router_address)
  end

  def simulate_amount_output(router_address, amount_in, reserve0, reserve1) do
    RouterContractV2.get_amount_out(amount_in, reserve0, reserve1)
    |> Ethers.call(to: router_address)
  end

  # This returns the minimum amount of WETH needed to get the specified amount of SHIB
  def simulate_amounts_input(router_address, amount_out, token0_address, token1_address) do
    IO.puts(
      "mx1 simulate_amounts_input amount_out: #{amount_out} token0_address: #{token0_address} token1_address: #{token1_address}"
    )

    RouterContractV2.get_amounts_in(amount_out, [token0_address, token1_address])
    |> Ethers.call(to: router_address)
  end

  #  This returns the maximum amount of output asset for the amount of input asset specified
  def simulate_amounts_output(router_address, 0, token0_address, token1_address),
    do: {:error, "Input amount 0 for simulate_amounts_output"}

  def simulate_amounts_output(router_address, amount_in, token0_address, token1_address) do
    IO.puts(
      "mx1 simulate_amounts_output amount_in: #{amount_in} token0_address: #{token0_address} token1_address: #{token1_address}"
    )

    RouterContractV2.get_amounts_out(amount_in, [token0_address, token1_address])
    |> Ethers.call(to: router_address)
  end

  def simulate_v2(amount, router_from, router_to, token0_address, token1_address) do
    with {:ok, trade1} <-
           router_from
           |> simulate_amounts_output(
             amount,
             token1_address,
             token0_address
           ),
         {:ok, trade2} <-
           router_to
           |> simulate_amounts_output(
             trade1 |> Enum.at(1),
             token0_address,
             token1_address
           ),
         amount_in <- trade1 |> Enum.at(0),
         amount_out <- trade2 |> Enum.at(1) do
      {:ok, amount_in, amount_out}
    end
  end

  def get_wallet_balance() do
    wallet_address = System.get_env("ACCOUNT_NUMBER")

    {:ok, eth_wallet_amount_wei} = Ethers.get_balance(wallet_address)

    {:ok, Ethers.Utils.from_wei(eth_wallet_amount_wei)}
  end

  def get_wallet_balance(address) do
    {:ok, token_amount_wei} = Ethers.get_balance(address)

    {:ok, Ethers.Utils.from_wei(token_amount_wei)}
  end

  def execute_trade(
        token0_address,
        token1_address,
        router_address,
        router_address_searched,
        tradable_amount,
        env \\ System.get_env("ENV")
      )

  def execute_trade(
        token0_address,
        token1_address,
        router_address,
        router_address_searched,
        tradable_amount,
        "prod"
      ) do
    IO.puts("sx1 in execute_trade prod")

    smart_contract_address =
      System.get_env("CONTRACT_ADDRESS")
      |> IO.inspect(label: "sx1 smart_contract_address")

    owner_wallet_address =
      System.get_env("ACCOUNT_NUMBER")
      |> IO.inspect(label: "sx1 owner_wallet_address")

    token0_address |> IO.inspect(label: "sx1 token0_address")
    token1_address |> IO.inspect(label: "sx1 token1_address")
    router_address |> IO.inspect(label: "sx1 router_address")
    router_address_searched |> IO.inspect(label: "sx1 router_address_searched")
    tradable_amount |> IO.inspect(label: "sx1 tradable_amount")

    Sabv1Contract.execute_trade(
      token0_address,
      token1_address,
      router_address,
      router_address_searched,
      tradable_amount
    )
    |> IO.inspect(label: "sx1 execute_trade pre Ethers.call()")
    |> Ethers.call(to: smart_contract_address)
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")
  end

  def execute_trade(
        token0_address,
        token1_address,
        router_address,
        router_address_searched,
        tradable_amount,
        "dev"
      ) do
    IO.puts("sx1 in execute_trade dev")

    smart_contract_address = System.get_env("SEPOLIA_CONTRACT_ADDRESS")
    owner_wallet_address = System.get_env("SEPOLIA_ACCOUNT_NUMBER")

    Sabv1Contract.execute_trade(
      token0_address,
      token1_address,
      router_address,
      router_address_searched,
      tradable_amount
    )
    |> Ethers.call(from: owner_wallet_address, to: smart_contract_address)

    # |> Ethers.call(to: smart_contract_address)
  end

  def test_smart_contract() do
    smart_contract_address = System.get_env("CONTRACT_ADDRESS")

    Sabv1Contract.get_string()
    |> Ethers.call(to: smart_contract_address)
  end
end
