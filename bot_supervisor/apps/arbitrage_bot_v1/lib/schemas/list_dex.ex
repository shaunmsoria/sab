defmodule ListDex do
  ##TODO defstruct deprecated
  defstruct name: "", list: []

  def get_list_dex_from_name(list_dex, name) do
    list_dex
    |> Enum.find(fn dex ->
      dex
      |> Map.get("name") == name
    end)
  end

  def get_dex_token_pair_from_address(address) when is_binary(address) do
    ConCache.get(:dex, "list_dex")
    |> Enum.reduce_while({}, fn dex_name, acc ->
      if is_nil(token_pair = ConCache.get(:dex, dex_name) |> Map.get(address)) do
        {:cont, acc}
      else
        {:halt, {:ok, {token_pair, dex_name}}}
      end
    end)
  end


  def get_token_pair_from_token_ids(list_dex, {_address, token_pair}) do
    with id0 <- token_pair["token0"]["address"],
         id1 <- token_pair["token1"]["address"] do
      _list_token_pairs =
        list_dex
        |> Enum.reduce_while(%{}, fn {_address, token_pair_searched}, acc ->

          searched_id0 =
            token_pair_searched["token0"]["address"]


          searched_id1 =
            token_pair_searched["token1"]["address"]


          if (String.equivalent?(searched_id0, id0) and String.equivalent?(searched_id1, id1)) or
               (String.equivalent?(searched_id1, id0) and String.equivalent?(searched_id0, id1)) do
            {:halt, token_pair_searched}
          else
            {:cont, acc}
          end
        end)
    end
  end

  def token_pair_from_list_dex(list_dex, token_pair) do

    list_dex
    |> Enum.reduce_while(%{}, fn {_address, token_pair_searched}, acc ->

      if (String.equivalent?(token_pair["token0"]["address"],
          token_pair_searched["token0"]["address"]) and
        String.equivalent?(token_pair["token1"]["address"],
          token_pair_searched["token1"]["address"])) or
          (String.equivalent?(token_pair["token0"]["address"],
          token_pair_searched["token1"]["address"])
            and String.equivalent?(token_pair["token1"]["address"],
            token_pair_searched["token0"]["address"])) do
              {:halt, token_pair_searched}
            else
              {:cont, acc}
            end
    end)

  end



  def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
    list_dex
    |> Map.get("content")
    |> Enum.reduce_while(%{}, fn {address_pair, _content} = token_pair, acc ->
      if  address_pair != address, do: {:cont, acc}, else: {:halt, token_pair}
    end)
  end

  def common_token_pair_in_two_dexs(dex0, dex1) do
    dex0
    |> Map.get("content")
    |> Enum.reduce([], fn token_pair0, acc ->
      result =
        get_token_pair_from_token_ids(dex1 |> Map.get("content"), token_pair0)

      if not is_nil(result), do: acc ++ [result], else: acc
    end)
  end
end
