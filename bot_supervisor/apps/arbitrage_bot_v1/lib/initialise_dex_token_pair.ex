defmodule InitialiseDexTokenPair do
  import Compute
  alias LogWritter, as: LW
  alias ListDex, as: LD
  alias DexSearch, as: DS
  alias TokenContext, as: TC


  ## TODO
  # Goal: update state_constructor to update the dabase with new token pairs from all dexs covered by the bot
  # Process:
  # 1.a create function to retrieve all_token_pairs of all or a specific dex passed as argument
  # 1.b check if length of all_token_pairs != from the current length of all_token_pairs
  # 1.c if no: do nothing
  #     if yes: get the missing token_pairs and update the database

  def run() do
    with list_dexs <- DS.query() |> Repo.all(),
         {:ok, list_dex_token_pairs_length_updated} <- get_all_token_pairs_length(list_dexs) do
    end
  end

  def get_all_token_pairs_length(list_dexs) do
    list_dexs
    |> Enum.map(fn dex ->
      maybe_update_dex_all_pairs(dex)
    end)
  end

  def maybe_update_dex_all_pairs(%Dex{all_pairs_length: nil, factory: factory} = dex) do
    with {:ok, dex_all_pairs_length} <- get_all_pairs_length(factory),
         {:ok, :all_pairs_retrieved} <- get_pairs_for_dex(dex, dex_all_pairs_length) do
      ## TODO
      # return updated dex with all_pairs_length
    end
  end

  def get_pairs_for_dex(%Dex{factory: factory} = dex, dex_all_pairs_length) do
    # 0..dex_all_pairs_length
    [0]
    |> Enum.map(fn n_pair ->
      get_pair(factory, n_pair)
      |> IO.inspect(label: "sx1 get_all_pairs")
    end)
  end

  def get_pair(factory, n_pair) do
    with {:ok, pair_address} <- get_all_pairs(factory, n_pair),
         {:ok, token0_address} <- pair_address |> contract(:token0),
         {:ok, token1_address} <- pair_address |> contract(:token1),
     {:ok, token0} <- maybe_add_token(token0_address),
      {:ok, token1} <-  maybe_add_token(token1_address) do
    end
  end

  def maybe_add_token(token_address) do
    case TS.with_address(token_address) do
      nil ->
        with {:ok, symbol} <- token_address |> contract(:symbol),
             {:ok, name} <- token_address |> contract(:name),
             {:ok, decimals} <- token_address |> contract(:decimals) do
          %{
            symbol: symbol,
            name: name,
            address: token_address,
            decimals: decimals
          }
          |> TC.insert()
        end

      %Token{} = token ->
        {:ok, token}
    end
  end

  def get_token_pair_price(token_pair) do
    # %{"price" => Compute.calculate_price(token_pair)}
    %{"price" => 0}
  end
end
