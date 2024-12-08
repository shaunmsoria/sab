defmodule Compute do
  def get_weth_balance(wallet_address) do
    WethContract.balance_of(wallet_address)
    |> Ethers.call(to: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
  end

  def get_shib_balance(wallet_address) do
    WethContract.balance_of(wallet_address)
    |> Ethers.call(to: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE")
  end

  def weth_total_supply() do
    WethContract.total_supply()
    |> Ethers.call(to: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
  end

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

  def calulcate_price("", _), do: {:error, "no pair address extracted from event"}

  def calculate_price(pair_address, :O_I) do
    with {:ok, [amount_0, amount_1, _time_stamp]} <-
           pair_address |> contract(:get_reserves) do
      case {is_integer(amount_0), is_integer(amount_1)} do
        {true, true} -> amount_0 / amount_1
        {_, _} -> {:error, "calculate_price issue with amount_0 #{amount_0} or #{amount_1}"}
      end

      # amount_0 / amount_1
    else
      _ -> {:error, "no price found for the pair #{pair_address}"}
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
    LiquidityPoolRouterContract.get_amount_in(amount_in, reserve0, reserve1)
    |> Ethers.call(to: router_address)
  end

  def simulate_amount_output(router_address, amount_in, reserve0, reserve1) do
    LiquidityPoolRouterContract.get_amount_out(amount_in, reserve0, reserve1)
    |> Ethers.call(to: router_address)
  end

  # This returns the amount of WETH needed to swap for X amount of SHIB
  def simulate_amounts_input(router_address, amount_out, token0_address, token1_address) do
    IO.puts("mx1 simulate_amounts_input")
    amount_out |> IO.inspect(label: "mx1 amount_out")
    token0_address |> IO.inspect(label: "mx1 token0_address")
    token1_address |> IO.inspect(label: "mx1 token1_address")

    LiquidityPoolRouterContract.get_amounts_in(amount_out, [token0_address, token1_address])
    |> Ethers.call(to: router_address)
  end



  #  This returns the amount of WETH for swapping X amount of SHIB
   def simulate_amounts_output(router_address, 0, token0_address, token1_address), do: {:error, "Input amount 0 for simulate_amounts_output"}
  def simulate_amounts_output(router_address, amount_in, token0_address, token1_address) do
    IO.puts("mx1 simulate_amounts_output")
    amount_in |> IO.inspect(label: "mx1 amount_in")
    token0_address |> IO.inspect(label: "mx1 token0_address")
    token1_address |> IO.inspect(label: "mx1 token1_address")

    LiquidityPoolRouterContract.get_amounts_out(amount_in, [token0_address, token1_address])
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

  def simulate(amount, router_from, router_to, token_pair) do
    with {:ok, trade1} <-
           router_from
           |> simulate_amounts_output(
             amount,
             token_pair["token1"]["address"],
             token_pair["token0"]["address"]
           )
           |> IO.inspect(label: "sx1 simulate_amounts_output trade1"),
         {:ok, trade2} <-
           router_to
           |> simulate_amounts_output(
             trade1 |> Enum.at(1),
             token_pair["token0"]["address"],
             token_pair["token1"]["address"]
           )
           |> IO.inspect(label: "sx1 simulate_amounts_output trade2"),
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

    # Sabv1Contract.execute_trade(
    #   true,
    #   token0_address,
    #   token1_address,
    #   tradable_amount
    # )
    # |> IO.inspect(label: "sx1 execute_trade pre Ethers.call()")
    |> Ethers.call(to: smart_contract_address)
    |> IO.inspect(label: "sx1 execute_trade post Ethers.call()")

    # |> Ethers.call(from: owner_wallet_address, to: smart_contract_address)
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
