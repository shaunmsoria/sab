defmodule CheckProfit do
  import Compute
  alias ListDex, as: LD
  alias LogWritter, as: LW
  alias DexSearch, as: DS
  alias TokenContext, as: TC
  alias ProfitableTradeContext, as: PTC
  alias TokenPairDexSearch, as: TPDS
  alias TokenPairDexContext, as: TPDC

  @dexs Libraries.dexs()
  @balancer Libraries.balancer()

  def run(_state, event_data) when is_map(event_data) do
    with true <-
           not String.equivalent?(event_data.event.address, ""),
         token_pair_dex_address <- event_data.event.address,
         {:ok,
          %TokenPairDex{
            token_pair: %TokenPair{status: "active"} = token,
            dex: %Dex{name: dex_name} = dex
          } = token_pair_dex} <-
           extract_token_pair_dex_details(token_pair_dex_address),
         {:ok, token_pair_dex_udpated} <-
           TPDC.update_token_pair_dex_price(token_pair_dex, :return_test),
         {:ok, list_of_profitable_trades} <-
           get_profitable_trade(token_pair_dex_udpated) do
      ExecuteTrade.run_v2(list_of_profitable_trades)
    else
      {:ok, %TokenPairDex{id: token_pair_id, token_pair: %TokenPair{status: "inactive"}}} ->
        # %{token_pair_id: token_pair_id, status: "inactive"}
        # |> IO.inspect(label: "sx1 Inactive TokenPairDex")

        IO.puts("sx1 TokenPair id: #{token_pair_id} Inactive")

      {:error, error_message} ->
        {:error, error_message} |> IO.inspect(label: "sx1")
    end
  end

  def extract_token_pair_dex_details(token_pair_dex_address) do
    with upcase_token_dex_address <- String.upcase(token_pair_dex_address),
         token_pair_dex_searched <-
           TPDS.with_upcase_address(upcase_token_dex_address) |> Repo.one(),
         true <- not is_nil(token_pair_dex_searched),
         token_pair_dex_preloaded <-
           token_pair_dex_searched
           |> Repo.preload([[token_pair: [:dexs, :token0, :token1]], :dex]) do
      {:ok, token_pair_dex_preloaded}
    else
      _ -> {:error, "No TokenPairDex for #{token_pair_dex_address}"}
    end
  end

  def get_profitable_trade(
        %TokenPairDex{
          dex:
            %Dex{
              name: dex_name
            } = dex,
          token_pair:
            %TokenPair{
              dexs: dexs,
              token0: token0,
              token1: token1
            } = token_pair,
          price: token_pair_dex_price,
          address: token_pair_dex_address
        } =
          token_pair_dex
      ) do
    profitable_trades_result =
      with {:ok, other_token_pair_dexs} <- TPDC.extract_other_token_pair_dexs(token_pair, dex) do
        other_token_pair_dexs
        |> Enum.reduce([], fn token_pair_dex_searched, acc ->
          acc ++ maybe_profitable_trade(token_pair_dex, token_pair_dex_searched)
        end)
      end

    {:ok, profitable_trades_result}
    |> LogWritter.ipt("sx1 get_profitable_trades result")
  end

  def maybe_profitable_trade(
        %TokenPairDex{price: token_pair_dex_price} = token_pair_dex,
        %TokenPairDex{} = token_pair_dex_searched
      ) do
    with {:ok,
          %TokenPairDex{price: token_pair_dex_searched_price, dex: %Dex{name: dex_searched_name}}} <-
           TPDC.update_token_pair_dex_price(token_pair_dex_searched),
         price_difference <-
           Compute.calculate_difference(token_pair_dex_price, token_pair_dex_searched_price) do
      case price_difference do
        0 ->
          []

        price_difference ->
          maybe_profitable_trade(token_pair_dex, token_pair_dex_searched, price_difference)
      end
    end
  end

  def maybe_profitable_trade(
        %TokenPairDex{
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
                  address: token1_address
                } = token_profit
            } = token_pair,
          address: token_pair_dex_address
        } = token_pair_dex,
        %TokenPairDex{
          dex:
            %Dex{
              router: router_searched_address
            } = dex_searched,
          address: token_pair_dex_searched_address
        } = token_pair_dex_searched,
        price_difference
      ) do
    with {:ok, [reserve0, reserve1, _block_timestamp_last]} <-
           token_pair_dex_address |> contract(:get_reserves),
         {:ok, [reserve0_searched, reserve1_searched, _block_timestamp_last]} <-
           token_pair_dex_searched_address |> contract(:get_reserves),
         token_pair_dex_price_O_I <- reserve0 / reserve1,
         token_pair_dex_searched_price_O_I <- reserve0_searched / reserve1_searched,
         {:ok, direction, _difference_pair_price_O_I} <-
           transaction_direction(token_pair_dex_searched_price_O_I - token_pair_dex_price_O_I),
         {:ok, simulated_profit_pre_gas, tradable_amount} <-
           simulate_profit_pre_gas_v2(
             router_address,
             token0_address,
             token1_address,
             reserve0,
             reserve1,
             router_searched_address,
             reserve0_searched,
             reserve1_searched,
             direction
           ),
         {:ok, gas_fee, simulated_profit_token_symbol} <-
           calculate_gas_price_for_trade_v2(token_profit),
         simulated_profit <-
           simulated_profit_pre_gas - gas_fee do
      simulated_profit |> IO.inspect(label: "sx1 simulated_profit")

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
            gas_fee: "#{gas_fee}",
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

  def calculate_gas_price_for_trade_v2(%Token{symbol: "WETH"}),
    do: {:ok, ConCache.get(:gas, :estimated_gas_fee), "WETH"}

  def calculate_gas_price_for_trade_v2(%Token{
        symbol: token_profit_symbol,
        address: token_profit_address
      }) do
    with estimated_gas_fee <- ConCache.get(:gas, :estimated_gas_fee),
         {:ok, gas_token_pair_address} <-
           Compute.get_pair_address(
             "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
             "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
             token_profit_address
           ),
         gas_token_pair <-
           TPDS.with_upcase_address(gas_token_pair_address |> String.upcase())
           |> Repo.one()
           |> Repo.preload(token_pair: [:token0, :token1]),
         {:ok, weth_location} <-
           locate_weth_in_token_pair_v2(gas_token_pair),
         {:ok, [reserve0, reserve1, _block_timestamp]} <-
           gas_token_pair_address |> contract(:get_reserves),
         {:ok, unit_weth_token_profit_price} <-
           calculate_gas_price_weth_price_v2(weth_location, reserve0, reserve1) do
      {:ok, unit_weth_token_profit_price * estimated_gas_fee, token_profit_symbol}
    end
  end

  def calculate_gas_price_weth_price_v2(:token0_weth, reserve0, reserve1),
    do: {:ok, reserve1 / (reserve0 * 1_000_000_000)}

  def calculate_gas_price_weth_price_v2(:token1_weth, reserve0, reserve1),
    do: {:ok, reserve0 / (reserve1 * 1_000_000_000)}

  def locate_weth_in_token_pair_v2(%TokenPairDex{
        token_pair: %TokenPair{token0: %Token{symbol: "WETH"}}
      }),
      do: {:ok, :token0_weth}

  def locate_weth_in_token_pair_v2(%TokenPairDex{
        token_pair: %TokenPair{token1: %Token{symbol: "WETH"}}
      }),
      do: {:ok, :token1_weth}

  def locate_weth_in_token_pair_v2(_), do: {:error, "WETH not find in token_pair"}

  def simulate_profit_pre_gas_v2(
        router_address,
        token0_address,
        token1_address,
        reserve0,
        reserve1,
        router_searched_address,
        reserve0_searched,
        reserve1_searched,
        :I_O
      ) do

    reserve0
    |> IO.inspect(label: "sx1 in simulate_profit_pre_gas :I_0 reserve0")

    with {:ok, estimate} <-
           router_searched_address
           |> estimate_extractor(
             reserve0,
             token1_address,
             token0_address,
             2
           ),
         {:ok, result} <-
           router_address
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token0_address,
             token1_address
           ),
         {:ok, amount_in, amount_out} <-
           simulate_v2(
             estimate |> Enum.at(0),
             router_searched_address,
             router_address,
             token0_address,
             token1_address
           ),
         pre_direction_gas_price_difference <- amount_out - amount_in do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def simulate_profit_pre_gas_v2(
        router_address,
        token0_address,
        token1_address,
        reserve0,
        reserve1,
        router_searched_address,
        reserve0_searched,
        reserve1_searched,
        :O_I
      ) do

    reserve0_searched
    |> IO.inspect(label: "sx1 in simulate_profit_pre_gas :0_I reserve0_searched")

    with {:ok, estimate} <-
           router_address
           |> estimate_extractor(
             reserve0_searched,
             token0_address,
             token1_address,
             2
           ),
         {:ok, result} <-
           router_searched_address
           |> simulate_amounts_output(
             estimate |> Enum.at(1),
             token0_address,
             token1_address
           ),
         {:ok, amount_in, amount_out} <-
           simulate_v2(
             estimate |> Enum.at(0),
             router_address,
             router_searched_address,
             token0_address,
             token1_address
           ),
         pre_direction_gas_price_difference <-
           amount_out - amount_in do
      {:ok, pre_direction_gas_price_difference, amount_in}
    end
  end

  def transaction_direction(pre_direction_gas_price_difference)
      when pre_direction_gas_price_difference < 0,
      do: {:ok, :O_I, pre_direction_gas_price_difference * -1}

  def transaction_direction(pre_gas_direction_price_difference)
      when pre_gas_direction_price_difference > 0,
      do: {:ok, :I_O, pre_gas_direction_price_difference}

  def transaction_direction(0), do: {:ok, false, 0}

  def estimate_extractor(router, amount, token0, token1, counter) when counter <= 0,
    do: {:error, "event not tradable"}

  def estimate_extractor(router, amount, token0, token1, counter) do
    list_divider = [
      1_000_000,
      1000,
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
