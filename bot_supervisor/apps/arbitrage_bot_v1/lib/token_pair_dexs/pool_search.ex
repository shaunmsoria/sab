defmodule PoolSearch do
  import Ecto.Query

  ## add Repo.all() or Repo.one() get the results
  def query() do
    from(Pool)
    # |> Repo.all()
  end

  def with_id(query \\ query(), id) do
    from(t in query, where: t.id == ^id)
  end

  def with_token_pair_id(query \\ query(), token_pair_id) do
    from(t in query, where: t.token_pair_id == ^token_pair_id)
  end

  def with_dex_id(query \\ query(), dex_id) do
    from(t in query, where: t.dex_id == ^dex_id)
  end

  def with_pool_address_id(query \\ query(), pool_address_id) do
    from(t in query, where: t.pool_address_id == ^pool_address_id)
  end

  def with_address(query \\ query(), address) do
    from(t in query, where: t.address == ^address)
  end

  def with_price(query \\ query(), price) do
    from(t in query, where: t.price == ^price)
  end

  def with_upcase_address(query \\ query(), upcase_address) do
    from(t in query, where: t.upcase_address == ^upcase_address)
  end

  def with_n_pair(query \\ query(), n_pair) do
    from(t in query, where: t.n_pair == ^n_pair)
  end

  def with_fee(query \\ query(), fee) do
    from(t in query, where: t.fee == ^fee)
  end

  def with_refresh_reserve(query \\ query(), refresh_reserve) do
    from(t in query, where: t.refresh_reserve == ^refresh_reserve)
  end

  def with_tick(query \\ query(), tick) do
    from(t in query, where: t.tick == ^tick)
  end

  def with_tick_spacing(query \\ query(), tick_spacin) do
    from(t in query, where: t.tick_spacin == ^tick_spacin)
  end

  def with_dex_abi(query \\ query(), dex_abi) do
    list_dex_id =
      from(d in Dex,
        where: d.abi == ^dex_abi,
        select: d.id
      )
      |> Repo.all()

    from(p in query, where: p.dex_id in ^list_dex_id)
  end


  def with_upcase_token_address_and_weth(query \\ query(), upcase_token_address) do
    token_id =
      from(t in Token,
        where: t.upcase_address == ^upcase_token_address,
        select: t.id
      )
      |> Repo.one()

    weth_id =
      from(t in Token,
        where: t.upcase_address == "0XC02AAA39B223FE8D0A0E5C4F27EAD9083C756CC2",
        select: t.id
      )
      |> Repo.one()

    ## TODO use sub_query above to find weth token pair

    token_weth_pair_id =
      from(tp in TokenPair,
        where:
          (tp.token0_id == ^token_id and
             tp.token1_id == ^weth_id) or
            (tp.token0_id == ^weth_id and
               tp.token1_id == ^token_id),
        select: tp.id
      )
      |> Repo.one()


      dex_id =
        from(d in Dex,
          where: d.name == "uniswap",
          where: d.abi == "uniswapV3",
          select: d.id
        )
        |> Repo.one()

    from(p in query,
      where: p.token_pair_id == ^token_weth_pair_id and p.dex_id == ^dex_id
    )
  end
end
