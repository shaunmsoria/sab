defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()
  # @trade_limit 10000000

  def run(_state, event_data) when is_map(event_data) do
    event_data.event.address
    |> IO.inspect(label: "sx1 event_data.event.address")

    with true <-
           not String.equivalent?(event_data.event.address, ""),
         price <- calculate_price(event_data.event.address) |> IO.inspect(label: "sx1 price"),
         address <- event_data.event.address |> IO.inspect(label: "sx1 address"),
         {:ok, {token_pair, dex_name}} <- found_dex_token_pair?(address),
         {:ok, token_pair_price_udpated} <-
           LD.update_token_pair_price(token_pair, dex_name, price),
         {:ok, list_of_profitable_trades} <-
           get_profitable_trade(token_pair_price_udpated, dex_name) do
      ExecuteTrade.run(list_of_profitable_trades)
    else
      error ->
        error |> IO.inspect(label: "sx1 error: no event address")
    end
  end

  def found_dex_token_pair?(address) do
    address |> IO.inspect(label: "sx1 in found_dex_token_pair? address result")

    with {:ok, token_pair} <- LD.get_dex_token_pair_from_address(address) do
      {:ok, token_pair}
    else
      _ -> {:error, "no token_pair found"}
    end
  end

  def update_token_pair_price(token_pair, dex_name, price) do
    with :ok <-
           ConCache.update(:dex, dex_name, fn dex_content ->
             {:ok, %{dex_content | token_pair["address"] => %{token_pair | "price" => price}}}
           end) do
      {:ok, ConCache.get(:dex, dex_name) |> Map.get(token_pair["address"])}
    end
  end

  def get_profitable_trade(token_pair_content, dex_name) do
    profitable_trades_result =
      with list_dex <-
             ConCache.get(:dex, "list_dex")
             |> Enum.filter(fn list_dex_name -> list_dex_name != dex_name end) do
        list_dex
        |> Enum.reduce([], fn dex_name_searched, acc ->
          case profitable_trade_from_dex(
                 LD.token_pair_from_list_dex(
                   ConCache.get(:dex, dex_name_searched),
                   token_pair_content
                 )
               ) do
            {true, token_pair_searched} ->
              {:ok, updated_token_pair_searched} =
                LD.update_token_pair_price(
                  token_pair_searched,
                  dex_name_searched,
                  Compute.calculate_price(token_pair_searched["address"])
                )

              price_difference =
                Compute.calculate_difference(
                  updated_token_pair_searched["price"],
                  token_pair_content["price"]
                )

              case is_trade_profitable?(
                     price_difference,
                     dex_name,
                     token_pair_content,
                     dex_name_searched,
                     updated_token_pair_searched
                   ) do
                {:ok, false, _price_difference_result, _estimated_profit,
                 _simulated_profit_token_symbol, _tradable_amount, _gas_fee} ->
                  acc

                {:ok, direction, true, estimated_profit, simulated_profit_token_symbol,
                 tradable_amount, gas_fee} ->
                  acc ++
                    [
                      {token_pair_content, updated_token_pair_searched, dex_name,
                       dex_name_searched, estimated_profit, simulated_profit_token_symbol,
                       direction, tradable_amount, gas_fee}
                    ]

                {:ok, _direction, false, _estimated_profit, _simulated_profit_token_symbol,
                 _tradable_amount, _gas_fee} ->
                  acc

                _ ->
                  %{
                    token_content: token_pair_content,
                    token_searched: updated_token_pair_searched
                  }
                  |> IO.inspect(label: "output: error in is_trade_profitable? for those tokens")

                  acc
              end

            false ->
              acc
          end
        end)
      end

    {:ok, profitable_trades_result}
    |> IO.inspect(label: "sx1 get_profitable_trades result")
  end

  def profitable_trade_from_dex(%{"address" => _address} = token_pair_searched),
    do: {true, token_pair_searched}

  def profitable_trade_from_dex(%{}), do: false

  def is_trade_profitable?(
        0,
        _dex_name,
        _is_trade_profitable,
        _dex_name_searched,
        _updated_token_pair_searched
      ),
      do: {false, 0}

  def is_trade_profitable?(
        _price_difference,
        dex_name,
        token_pair_content,
        dex_name_searched,
        token_pair_searched
      ) do
    with router_address <-
           @dexs[dex_name]["router"]
           |> IO.inspect(label: "sx1 router_address"),
         router_address_searched <-
           @dexs[dex_name_searched]["router"]
           |> IO.inspect(label: "sx1 router_address_searched"),
         {:ok, [reserve0, reserve1, _block_timestamp_last]} <-
           token_pair_content["address"]
           |> contract(:get_reserves)
           |> IO.inspect(label: "sx1 get_reserves pair_address_dex_name"),
         {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <-
           token_pair_searched["address"]
           |> contract(:get_reserves)
           |> IO.inspect(label: "sx1 get_reserves pair_address_dex_name_searched"),
         content_pair_price_O_I <-
           (reserve0 / reserve1)
           |> IO.inspect(label: "sx1 content_pair_price"),
         searched_pair_price_O_I <-
           (reserve0_searched / reserve1_searched)
           |> IO.inspect(label: "sx1 searched_pair_price"),
         {:ok, direction, _difference_pair_price_O_I} <-
           transaction_direction(searched_pair_price_O_I - content_pair_price_O_I)
           |> IO.inspect(label: "sx1 transaction_direction"),
         {:ok, simulated_profit_pre_gas, tradable_amount} <-
           simulate_profit_pre_gas(
             router_address,
             reserve0,
             reserve1,
             router_address_searched,
             reserve0_searched,
             reserve1_searched,
             token_pair_content,
             direction
           )
           |> IO.inspect(label: "sx1 simulate_profit_pre_gas"),
         {:ok, gas_fee, simulated_profit_token_symbol} <-
           calculate_gas_price_for_trade(token_pair_content["token1"])
           |> IO.inspect(label: "sx1 gas_fee in token1 amount"),
         simulated_profit <-
           (simulated_profit_pre_gas - gas_fee)
           |> IO.inspect(label: "sx1 simulated_profit") do
      # {:ok, direction, simulated_profit > 0, simulated_profit, simulated_profit_token_symbol, tradable_amount, gas_fee}
      {:ok, direction, simulated_profit > 0, simulated_profit, simulated_profit_token_symbol,
       tradable_amount, gas_fee}
    end
  end

  def calculate_gas_price_for_trade(%{"symbol" => "WETH"}),
    do: {:ok, ConCache.get(:gas, :estimated_gas_fee), "WETH"}

  def calculate_gas_price_for_trade(profit_token) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee),
         {:ok, gas_token_pair} <-
           Compute.get_pair_address(
             "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
             "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
             profit_token["address"]
           ),
         {:ok, weth_location} <- locate_weth_in_token_pair(gas_token_pair),
         {:ok, [reserve0, reserve1, _block_timestamp]} <-
           gas_token_pair |> contract(:get_reserves),
         {:ok, unit_weth_token_profit_price} <-
           calculate_gas_price_weth_price(weth_location, reserve0, reserve1) do
      {:ok, unit_weth_token_profit_price * estimated_gas_fee, profit_token["symbol"]}
    end
  end

  def calculate_gas_price_weth_price(:token0_weth, reserve0, reserve1),
    do: {:ok, reserve1 / (reserve0 * 1_000_000_000)}

  def calculate_gas_price_weth_price(:token1_weth, reserve0, reserve1),
    do: {:ok, reserve0 / (reserve1 * 1_000_000_000)}

  def locate_weth_in_token_pair(%{"token0" => %{"symbol" => "WETH"}}), do: {:ok, :token0_weth}
  def locate_weth_in_token_pair(%{"token1" => %{"symbol" => "WETH"}}), do: {:ok, :token1_weth}
  def locate_weth_in_token_pair(_), do: {:error, "WETH not find in token_pair"}

  def transaction_direction(pre_direction_gas_price_difference)
      when pre_direction_gas_price_difference < 0,
      do: {:ok, :O_I, pre_direction_gas_price_difference * -1}

  def transaction_direction(pre_gas_direction_price_difference)
      when pre_gas_direction_price_difference > 0,
      do: {:ok, :I_O, pre_gas_direction_price_difference}

  def transaction_direction(0), do: {:ok, false, 0}

  # def simulate_profit_pre_gas(router_address, reserve0, reserve1, router_address_searched, reserve0_searched, reserve1_searched, _token_pair_content, :I_O) do
  #     with  tradable_amount <- reserve1_searched / 2
  #             |> IO.inspect(label: "sx1 tradable_amount"),
  #           {:ok, simulated_amount_out_reserve_0} <- router_address_searched |> simulate_amount_input(tradable_amount, reserve1_searched, reserve0_searched)
  #             |> IO.inspect(label: "sx1 simulate_amount_output content"),
  #           {:ok, simulated_amount_out_reserve_1_searched} <- router_address |> simulate_amount_output(simulated_amount_out_reserve_0, reserve0, reserve1)
  #             |> IO.inspect(label: "sx1 simulate_amount_output searched"),
  #           pre_direction_gas_price_difference <- simulated_amount_out_reserve_1_searched - tradable_amount
  #             |> IO.inspect(label: "sx1 pre_direction_gas_price_difference :I_O") do
  #             {:ok, pre_direction_gas_price_difference, tradable_amount}
  #     end
  # end

  def simulate_profit_pre_gas(
        router_address,
        reserve0,
        reserve1,
        router_address_searched,
        reserve0_searched,
        reserve1_searched,
        token_pair,
        :I_O
      ) do
    IO.puts("sx1 in simulate_profit_pre_gas :I_0")
    reserve0 |> IO.inspect(label: "sx1 reserve0 value")

    # (reserve0 / 1_000_000_000_000)
    # |> trunc()
    # |> IO.inspect(label: "sx1 reserve0 / 1000000000000 value")

    # with  min_amount <- (reserve0_searched / 2) |> trunc() |> Ethers.Utils.from_wei() |> trunc()
    # with min_amount <-
    #        (reserve0 / 1_000_000_000_000)
    #        |> trunc()
    #        |> IO.inspect(label: "sx1 min_amount"),
    with {:ok, estimate} <-
           router_address_searched
           |> estimate_extractor(
             reserve0,
             token_pair["token1"]["address"],
             token_pair["token0"]["address"],
             18
           )
           |> IO.inspect(label: "sx1 estimate :I_0"),
         #  {:ok, estimate} <-
         #    router_address_searched
         #    |> simulate_amounts_input(
         #      min_amount,
         #      token_pair["token1"]["address"],
         #      token_pair["token0"]["address"]
         #    )
         #    |> IO.inspect(label: "sx1 estimate"),
         {:ok, result} <-
           router_address
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token_pair["token0"]["address"],
             token_pair["token1"]["address"]
           )
           |> IO.inspect(label: "sx1 result"),
         {:ok, amount_in, amount_out} <-
           simulate(estimate |> Enum.at(0), router_address_searched, router_address, token_pair),
         pre_direction_gas_price_difference <-
           (amount_out - amount_in)
           |> IO.inspect(label: "sx1 pre_direction_gas_price_difference :I_O") do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def simulate_profit_pre_gas(
        router_address,
        reserve0,
        reserve1,
        router_address_searched,
        reserve0_searched,
        reserve1_searched,
        token_pair,
        :O_I
      ) do
    IO.puts("sx1 in simulate_profit_pre_gas :0_I")
    reserve0_searched |> IO.inspect(label: "sx1 reserve0_searched value")

    # (reserve0_searched / 1_000_000_000_000)
    # |> trunc()
    # |> IO.inspect(label: "sx1 reserve0_searched / 1000000000000 value")

    # with  min_amount <- (reserve0 / 2) |> trunc() |> Ethers.Utils.from_wei() |> trunc()
    # with min_amount <-
    #        (reserve0_searched / 1_000_000_000_000)
    #        |> trunc()
    #        |> IO.inspect(label: "sx1 min_amount"),
    with {:ok, estimate} <-
           router_address
           |> estimate_extractor(
             reserve0_searched,
             token_pair["token1"]["address"],
             token_pair["token0"]["address"],
             18
           )
           |> IO.inspect(label: "sx1 estimate :0_I"),
         #  {:ok, estimate} <-
         #    router_address
         #    |> simulate_amounts_input(
         #      min_amount,
         #      token_pair["token1"]["address"],
         #      token_pair["token0"]["address"]
         #    )
         #    |> IO.inspect(label: "sx1 estimate"),
         {:ok, result} <-
           router_address_searched
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token_pair["token0"]["address"],
             token_pair["token1"]["address"]
           )
           |> IO.inspect(label: "sx1 result"),
         {:ok, amount_in, amount_out} <-
           simulate(estimate |> Enum.at(0), router_address, router_address_searched, token_pair),
         pre_direction_gas_price_difference <-
           (amount_out - amount_in)
           |> IO.inspect(label: "sx1 pre_direction_gas_price_difference :O_I") do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def safety_tradable_amount(reserve0, reserve1),
    do: if(reserve0 > reserve1, do: {:ok, reserve1}, else: {:ok, reserve0})

  # @divider [
  #   1_000_000_000_000,
  #   500_000_000_000,
  #   1_000_000_000,
  #   500_000_000,
  #   1_000_000,
  #   500_000,
  #   1000,
  #   500,
  #   100,
  #   50,
  #   10,
  #   9,
  #   8,
  #   7,
  #   6,
  #   5,
  #   4,
  #   3,
  #   2
  # ]
  # @divider [1000000000000, 1000000000, 1000000, 1000, 100, 10, 8, 6, 4, 2]
  # @divider_up [500000000000, 500000000, 500000, 500, 50, 9, 7, 5, 3, 2]
  def estimate_extractor(router, amount, token0, token1, counter) when counter <= 0,
    do: {:error, "event not tradable"}

  def estimate_extractor(router, amount, token0, token1, counter) do
    list_divider = [
      1_000_000_000_000,
      500_000_000_000,
      1_000_000_000,
      500_000_000,
      1_000_000,
      500_000,
      1000,
      500,
      100,
      50,
      10,
      9,
      8,
      7,
      6,
      5,
      4,
      3,
      2
    ]

    with divider <- list_divider |> Enum.at(counter) |> trunc(),
         min_amount <- (amount / divider) |> trunc(),
         {:ok, estimate} <-
           router
           |> simulate_amounts_input(
             min_amount,
             token0,
             token1
           ) do
      {:ok, estimate}
    else
      {:error,
       %{
         "code" => _code,
         "data" => _data,
         "message" => "execution reverted: ds-math-sub-underflow"
       }} ->
        estimate_extractor(router, amount, token0, token1, counter - 2)

      {:error,
       %{
         "code" => _code,
         "data" => _data,
         "message" => "execution reverted: UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
       }} ->
        estimate_extractor(router, amount, token0, token1, counter + 1)
    end
  end
end
