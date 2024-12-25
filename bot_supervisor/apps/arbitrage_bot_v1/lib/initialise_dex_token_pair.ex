defmodule InitialiseDexTokenPair do
  import Compute
  alias LogWritter, as: LW
  alias ListDex, as: LD
  alias DexSearch, as: DS
  alias DexContext, as: DC
  alias TokenSearch, as: TS
  alias TokenContext, as: TC
  alias TokenPairSearch, as: TPS
  alias TokenPairContext, as: TPC
  alias TokenPairDexContext, as: TPDC
  alias LogWritter, as: LW

  ## TODO
  # remove comment in get_pairs_for_dex to allow the system to update for all token_pairs

  def run() do
    with list_dexs <- DS.query() |> Repo.all(),
         {:ok, list_dex_token_pairs_length_updated} <- get_all_token_pairs_length(list_dexs) do
      {:ok, :database_ready}
    end
  end

  def get_all_token_pairs_length(list_dexs) do
    list_dexs
    |> Enum.map(fn dex ->
      maybe_update_dex_all_pairs(dex)
    end)
  end

  def maybe_update_dex_all_pairs(%Dex{all_pairs_length: nil, factory: factory} = dex) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(factory) ,
         {:ok, :all_pairs_retrieved} <- get_pairs_for_dex(dex, dex_all_pairs_length) do
      {:ok, dex}
    end
  end

  def maybe_update_dex_all_pairs(
        %Dex{
          name: dex_name,
          all_pairs_length: current_all_pairs_length,
          factory: factory
        } = dex
      ) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(factory) do
      max_length =
        case  dex_name  do
          "pancakeswap" ->  668
          "sushiswap" -> 4143
          _ -> 5000
        end


      if dex_all_pairs_length <= current_all_pairs_length do
      # if max_length == current_all_pairs_length do
      # if max_length <= current_all_pairs_length do
        IO.puts("dex: #{dex_name} is up to date")
      else
        get_pairs_for_dex(dex, dex_all_pairs_length, current_all_pairs_length + 1)
        IO.puts("dex: #{dex_name} have been updated")
      end

      {:ok, dex}
    end
  end

  def sanitise_current_all_pairs_length(0), do: 0
  def sanitise_current_all_pairs_length(current_all_pairs_length), do: (current_all_pairs_length - 1)

  def get_pairs_for_dex(%Dex{} = dex, dex_all_pairs_length, start_all_pairs_length \\ 0) do
    sanitise_current_all_pairs_length(start_all_pairs_length)..(dex_all_pairs_length - 1)
    # start_all_pairs_length..5000
    |> Enum.map(fn n_pair ->
      n_pair |> IO.inspect(label: "n_pair")

      get_or_create_pair_for_dex(dex, n_pair)
    end)

    {:ok, :all_pairs_retrieved}
  end


  def get_or_create_pair_for_dex(%Dex{name: dex_name, factory: factory} = dex, n_pair) do
    with {:ok, pair_address} <-
           get_all_pairs(factory, n_pair) |> IO.inspect(label: "sx1 get_all_pairs"),
         {:ok, token0_address} <- pair_address |> contract(:token0),
         {:ok, token1_address} <- pair_address |> contract(:token1),
         {:ok, token0} <- maybe_add_token(token0_address),
         {:ok, token1} <- maybe_add_token(token1_address),
         {:ok, token_pair} <- maybe_add_token_pair(token0, token1, dex),
         {:ok, token_pair_dex} <-
           TPDC.update_with_token_pair_and_dex(token_pair, dex, %{
             address: pair_address,
             upcase_address: pair_address |> String.upcase(),
             n_pair: n_pair
           }),
         {:ok, updated_dex} <- dex |> DC.update(%{all_pairs_length: n_pair}) do
      {:ok, token_pair_dex}
    else
      error ->
        :timer.sleep(3600000)

        LW.ipt(
          "dex: #{dex_name} for n_pair: #{n_pair} not retrieved because of: #{inspect(error)}"
        )

        get_or_create_pair_for_dex(%Dex{factory: factory} = dex, n_pair)
    end
  end

  def maybe_add_token_pair(
        %Token{id: token0_id},
        %Token{id: token1_id},
        %Dex{} = dex
      ) do
    case TPS.with_token0_id(token0_id)
         |> TPS.with_token1_id(token1_id)
         |> Repo.one() do
      nil ->
        with {:ok, token_pair} <-
               %{
                 token0_id: token0_id,
                 token1_id: token1_id,
                 dexs: [dex],
                 status: "inactive"
               }
               |> TPC.insert() do
          {:ok, token_pair}
        end

      %TokenPair{} = token_pair ->
        with {:ok, updated_token_pair} <-
               token_pair
               |> TPC.update(%{
                 dexs: [dex],
                 status: "active"
               }) do
          {:ok, updated_token_pair}
        end
    end
  end

  def maybe_add_token(token_address) do
    case TS.with_address(token_address) |> Repo.one() do
      nil ->
        with {:ok, symbol, name, decimals} <- token_address |> get_contract_for_token_address(),
             {:ok, token} <-
               %{
                 symbol: symbol,
                 name: name,
                 address: token_address,
                 upcase_address: token_address |> String.upcase(),
                 decimals: decimals
               }
               |> TC.insert() do
          {:ok, token}
        end

      %Token{} = token ->
        {:ok, token}
    end
  end

  def get_contract_for_token_address(token_address) do
    with symbol_result <-
           (try do
              token_address |> contract(:symbol)
            rescue
              e ->
                {:ok, token_address}
            end),
         name_result <-
           (try do
              token_address |> contract(:name)
            rescue
              e ->
                {:ok, token_address}
            end),
         decimals_result <-
           (try do
              token_address |> contract(:decimals)
            rescue
              e ->
                {:ok, 0}
            end) do
      {:ok, sanitise_param(symbol_result), sanitise_param(name_result),
       sanitise_param(decimals_result, :decimals)}
      |> IO.inspect(label: "sx1 get_contract_for_token_address")

    end
  end

  def sanitise_param({:ok, param}) when is_binary(param) do
    case param do
      "0x" -> nil
      param ->
        split_param = param |> String.slice(0..254) |> inspect() |> String.trim("\"")

    end
  end

  def sanitise_param(_), do: nil

  def sanitise_param({:ok, param}, :decimals) when is_integer(param), do: param
  def sanitise_param(_, :decimals), do: 0

end
