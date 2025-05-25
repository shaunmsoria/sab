defmodule PoolV2CheckProfit do
  import Compute
  alias ListDex, as: LD
  alias LogWritter, as: LW
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias ProfitableTradeContext, as: PTC
  alias PoolSearch, as: PS
  alias PoolContext, as: PC

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(
        %Pool{reserve0: reserve0, reserve1: reserve1} = pool_event,
        {0, amount0_out, amount1_in, 0}
      ),
      do: calculate_ratio(pool_event, amount1_in, reserve1)

  def run(
        %Pool{reserve0: reserve0, reserve1: reserve1} = pool_event,
        {amount0_in, 0, 0, amount1_out}
      ),
      do: calculate_ratio(pool_event, amount0_in, reserve0)

  def calculate_ratio(pool, _amount, nil),
    do: update_reserves_from_event(pool)

  def calculate_ratio(pool, amount, reserve) do
    amount |> IO.inspect(label: "sx1 amount")

    reserve
    |> calculate_pool_ratio()
    |> Decimal.from_float()
    |> Decimal.to_string(:normal)
    |> IO.inspect(label: "sx1 calculate_pool_ratio Decimal")

    # if calculate_event_ratio(amount, reserve) >= calculate_pool_ratio(reserve) do
    if amount >= calculate_pool_ratio(reserve) do
      action_event(pool)
    else
      update_reserves_from_event(pool)
    end
  end

  def update_reserves_from_event(%Pool{id: token_pair_id, refresh_reserve: false} = pool) do
    IO.puts("sx1 token_pair_id: #{token_pair_id} below threshold")
    {:ok, pool}
  end

  def update_reserves_from_event(
        %Pool{
          id: pool_id,
          address: pool_address,
          refresh_reserve: true
        } = pool
      ) do
    with {:ok, updated_price, updated_reserve0, updated_reserve1} <-
           calculate_price(pool_address) do
      {:ok, updated_pool} =
        pool
        |> PC.update(%{
          price: updated_price |> Float.to_string(),
          reserve0: updated_reserve0 |> Integer.to_string(),
          reserve1: updated_reserve1 |> Integer.to_string(),
          refresh_reserve: false
        })

      IO.puts(
        "Pool with id: #{pool_id} updated price: #{updated_price} / reserve0: #{updated_reserve0} / reserve1: #{updated_reserve1} / refresh_reserve: false updated"
      )

      {:ok, updated_pool}
    else
      {:error, message} -> message |> LW.ipt("update_reserves_from_event failed: ")
    end
  end

  def sanitise_price(reserve0, reserve1)
      when is_integer(reserve0) and is_integer(reserve1) and reserve1 > 0,
      do: reserve0 / reserve1

  def sanitise_price(_reserve0, _reserve1), do: 0

  def action_event(%Pool{} = pool_event) do
    with {:ok, pool_event_udpated} <-
           PC.update_pool_price(pool_event, :pool_event),
         {:ok, list_of_profitable_trades} <-
           get_profitable_trade(pool_event_udpated) do
      ExecuteTrade.run_v2(list_of_profitable_trades)
    end
  end

  def calculate_event_ratio(_amount_event, nil), do: 0
  def calculate_event_ratio(nil, _amount_pool), do: 0
  def calculate_event_ratio(_amount_event, 0), do: 0

  def calculate_event_ratio(amount_event, amount_pool_raw) do
    amount_pool = String.to_integer(amount_pool_raw)

    amount_event / amount_pool
  end

  # @threshold_percentage 0.001
  @threshold_percentage 0.02

  # @threshold_percentage 0.0000001
  def calculate_pool_ratio(nil), do: 0
  def calculate_pool_ratio(0), do: 0

  def calculate_pool_ratio(amount_pool),
    do: (amount_pool |> String.to_integer()) * @threshold_percentage

  def get_profitable_trade(
        %Pool{
          dex:
            %Dex{
              name: dex_name
            } = dex,
          token_pair:
            %TokenPair{
              token0: token0,
              token1: token1
            } = token_pair,
          price: pool_event_price,
          address: pool_address
        } =
          pool_event
      ) do
    profitable_trades_result =
      with {:ok, other_pools} <- PC.extract_other_pools(token_pair, dex) do
        other_pools
        |> Enum.reduce([], fn pool_searched, acc ->
          acc ++ maybe_profitable_trade(pool_event, pool_searched)
        end)
      else
        {:error, message} ->
          message |> LogWritter.ipt("sx1 no_profitable_trades")
          []
      end

    {:ok, profitable_trades_result}
    |> LogWritter.ipt("sx1 get_profitable_trades result")
  end

  def maybe_profitable_trade(
        %Pool{price: pool_event_price} = pool_event,
        %Pool{} = pool_searched
      ) do
    with {:ok, %Pool{price: pool_searched_price, dex: %Dex{name: dex_searched_name}}} <-
           PC.update_pool_price(pool_searched),
         price_difference <-
           Compute.calculate_difference(pool_event_price, pool_searched_price) do
      case price_difference do
        0 ->
          []

        price_difference ->
          maybe_profitable_trade(pool_event, pool_searched, price_difference)
      end
    end
  end

  def maybe_profitable_trade(
        %Pool{
          dex:
            %Dex{
              router: router_address
            } = dex_emitted,
          token_pair:
            %TokenPair{
              token0: %Token{
                address: token0_address
              },
              token1:
                %Token{
                  symbol: token_profit_symbol,
                  address: token1_address
                } = token_profit
            } = token_pair,
          address: pool_event_address
        } = pool_event,
        %Pool{
          dex:
            %Dex{
              router: router_searched_address
            } = dex_searched,
          address: pool_searched_address
        } = pool_searched,
        price_difference
      ) do
    with {:ok, simulated_profit_pre_gas, tradable_amount, direction} <-
           simulate_profit_pre_gas_v3(
             pool_event,
             pool_searched
           ),
         {gas_fee_in_token_profit_amount, simulated_profit_token_symbol} <-
           calculate_gas_price_for_trade_v3(token_profit),
         simulated_profit <-
           simulated_profit_pre_gas - gas_fee_in_token_profit_amount do
      simulated_profit_pre_gas |> LW.ipt("sx1 simulated_profit_pre_gas")
      gas_fee_in_token_profit_amount |> LW.ipt("sx1 gas_fee_in_token_profit_amount")
      simulated_profit |> LW.ipt("sx1 simulated_profit in #{token_profit_symbol}")

      if simulated_profit > 0 do
        {:ok, profitable_trade} =
          PTC.insert(%{
            token_pair: token_pair,
            dex_emitted: dex_emitted,
            dex_searched: dex_searched,
            token_profit: token_profit,
            estimated_profit: "#{simulated_profit}",
            direction: Atom.to_string(direction),
            tradable_amount: "#{tradable_amount}",
            gas_fee: "#{gas_fee_in_token_profit_amount}",
            smart_contract_response: "not_sent_to_smart_contract"
          })

        [profitable_trade]
      else
        []
      end
    else
      error ->
        error |> LW.ipt("sx1 error in maybe_profitable_trade")
        []
    end
  end

  def simulate_profit_pre_gas_v3(
        %Pool{
          dex: %Dex{
            router: router_event_address
          },
          token_pair: %TokenPair{
            token0: %Token{
              address: token0_address
            },
            token1: %Token{
              address: token1_address,
              decimals: token1_decimals
            }
          },
          address: pool_event_address,
          price: pool_event_price_O_I,
          reserve0: reserve0,
          reserve1: reserve1
        },
        %Pool{
          dex: %Dex{
            router: router_searched_address
          },
          address: pool_searched_address,
          price: pool_searched_price_O_I,
          reserve0: reserve0_searched,
          reserve1: reserve1_searched
        }
      ) do
    with {:ok, direction} <-
           transaction_direction(
             String.to_float(pool_searched_price_O_I) -
               String.to_float(pool_event_price_O_I)
           ) do
      case direction do
        :O_I ->
          with {:ok, estimate} <-
                 router_event_address
                 |> estimate_extractor(
                   format_reserve(reserve0_searched),
                   token1_address,
                   token0_address,
                   #  22
                   2
                 )
                 |> LW.ipt("sx1 estimate"),
               {:ok, amount_in, amount_out} <-
                 simulate_v2(
                   estimate |> Enum.at(0),
                   router_event_address,
                   router_searched_address,
                   token0_address,
                   token1_address
                 )
                 |> LW.ipt("sx1 {amount_in, amount_out}"),
               pre_direction_gas_price_difference <-
                 (amount_out - amount_in) / 10 ** token1_decimals do
            {:ok, pre_direction_gas_price_difference, amount_in, direction}
          end

        :I_O ->
          with {:ok, estimate} <-
                 router_searched_address
                 |> estimate_extractor(
                   format_reserve(reserve0_searched),
                   token1_address,
                   token0_address,
                   #  22
                   2
                 )
                 |> LW.ipt("sx1 estimate"),
               {:ok, amount_in, amount_out} <-
                 simulate_v2(
                   estimate |> Enum.at(0),
                   router_searched_address,
                   router_event_address,
                   token0_address,
                   token1_address
                 )
                 |> LW.ipt("sx1 {amount_in, amount_out}"),
               pre_direction_gas_price_difference <-
                 (amount_out - amount_in) / 10 ** token1_decimals do
            {:ok, pre_direction_gas_price_difference, amount_in, direction}
          end
      end
    end
  end

  def calculate_gas_price_for_trade_v2(%Token{symbol: "WETH"}),
    do: {:ok, ConCache.get(:gas, :estimated_gas_fee), "WETH"}

  def calculate_gas_price_for_trade_v2(%Token{
        symbol: token_profit_symbol,
        address: token_profit_address
      }) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee),
         {:ok, gas_pool_address} <-
           Compute.get_pair_address(
             "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
             "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
             token_profit_address
           ),
         gas_token_pair <-
           PS.with_upcase_address(gas_pool_address |> String.upcase())
           |> Repo.one()
           |> Repo.preload(token_pair: [:token0, :token1]),
         {:ok, weth_location} <-
           locate_weth_in_token_pair_v2(gas_token_pair),
         {:ok, [reserve0, reserve1, _block_timestamp]} <-
           gas_pool_address |> pool("uniswapV2", :get_reserves),
         {:ok, unit_weth_token_profit_price} <-
           calculate_gas_price_weth_price_v2(weth_location, reserve0, reserve1) do
      {:ok, unit_weth_token_profit_price * estimated_gas_fee, token_profit_symbol}
    end
  end

  def calculate_gas_price_weth_price_v2(:token0_weth, reserve0, reserve1),
    do: {:ok, reserve1 / (reserve0 * 1_000_000_000)}

  def calculate_gas_price_weth_price_v2(:token1_weth, reserve0, reserve1),
    do: {:ok, reserve0 / (reserve1 * 1_000_000_000)}

  def locate_weth_in_token_pair_v2(%Pool{
        token_pair: %TokenPair{token0: %Token{symbol: "WETH"}}
      }),
      do: {:ok, :token0_weth}

  def locate_weth_in_token_pair_v2(%Pool{
        token_pair: %TokenPair{token1: %Token{symbol: "WETH"}}
      }),
      do: {:ok, :token1_weth}

  def locate_weth_in_token_pair_v2(_), do: {:error, "WETH not find in token_pair"}

  def transaction_direction(pre_direction_gas_price_difference)
      when pre_direction_gas_price_difference < 0,
      do: {:ok, :O_I}

  def transaction_direction(pre_gas_direction_price_difference)
      when pre_gas_direction_price_difference > 0,
      do: {:ok, :I_O}

  def transaction_direction(0), do: {:ok, false, 0}

  def estimate_extractor(router, amount, token0, token1, counter) when counter < 0,
    do: {:error, "event not tradable"}

  def estimate_extractor(router, amount, token0, token1, counter) do
    list_divider = [
      # 1_000_000_000_000,
      # 500_000_000_000,
      # 10_000_000_000,
      # 5_000_000_000,
      # 1_000_000_000,
      # 500_000_000,
      # 100_000_000,
      # 50_000_000,
      # 10_000_000,
      # 5_000_000,
      # 1_000_000,
      # 500_000,
      # 100_000,
      # 50000,
      # 10000,
      # 5000,
      # 1000,
      # 500,
      # 100,
      # 50,
      10,
      5,
      2
    ]

    with divider <- list_divider |> Enum.at(counter) |> trunc(),
         max_swappable_amount <- (amount / divider) |> trunc(),
         {:ok, estimate} <-
           router
           |> simulate_amounts_input(
             max_swappable_amount,
             token0,
             token1
           ) do
      {:ok, estimate}
    else
      {:error,
       %{
         "code" => _code,
         "data" => _data,
         "message" => message
       }} ->
        case {String.contains?(message, "ds-math-sub-underflow"),
              String.contains?(message, "INSUFFICIENT_OUTPUT_AMOUNT")} do
          {true, false} -> estimate_extractor(router, amount, token0, token1, counter - 2)
          {false, true} -> estimate_extractor(router, amount, token0, token1, counter + 1)
          {_, _} -> {:error, message}
        end
    end
  end

  def format_reserve(reserve_amount) when is_binary(reserve_amount) do
    reserve_amount
    |> String.split(".")
    |> Enum.at(0)
    |> String.to_integer()
  end

  def format_reserve(reserve_amount) when is_float(reserve_amount) do
    reserve_amount
    |> Float.to_integer()
  end

  def format_reserve(reserve_amount) when is_integer(reserve_amount), do: reserve_amount
end
