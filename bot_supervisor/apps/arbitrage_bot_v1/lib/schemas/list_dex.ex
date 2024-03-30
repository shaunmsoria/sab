defmodule ListDex do
  ##TODO defstruct deprecated
  defstruct name: "", list: []

  def get_list_dex_from_name(list_dex, name) when is_list(list_dex) do
    list_dex
    |> Enum.find(fn dex ->
      dex
      |> Map.get("name") == name
    end)
  end

  def get_dex_token_pair_from_address(state, address)
      when is_list(state) and is_binary(address) do
    state
    |> Enum.reduce_while(%{}, fn list_dex, acc ->
      result_dex_token_pair =
        is_address_in_list_dex?(list_dex, address)

      if result_dex_token_pair == %{}, do: {:cont, acc}, else: {:halt, result_dex_token_pair}
    end)
  end

  def get_token_pair_from_token_ids(list_dex, token_pair) when is_list(list_dex) do
    # token_pair |> IO.inspect(label: "sx1 token_pair")
    with id0 <- token_pair |> Map.get("token0") |> Map.get("address"),
         id1 <- token_pair |> Map.get("token1") |> Map.get("address") do
      _list_token_pairs =
        list_dex
        |> Enum.reduce_while(%{}, fn token_pair_searched, acc ->


          searched_id0 =
            token_pair_searched |> Map.get("token0") |> Map.get("address")


          searched_id1 =
            token_pair_searched |> Map.get("token1") |> Map.get("address")


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
    |> Enum.reduce_while(%{}, fn token_pair_searched, acc ->
      if (String.equivalent?(token_pair["token0"]["address"], token_pair_searched["token0"]["address"])
            and String.equivalent?(token_pair["token1"]["address"], token_pair_searched["token1"]["address"])) or
            (String.equivalent?(token_pair["token0"]["address"], token_pair_searched["token1"]["address"])
            and String.equivalent?(token_pair["token1"]["address"], token_pair_searched["token0"]["address"])) do
              {:halt, token_pair_searched}
            else
              {:cont, acc}
            end
    end)

  end



  def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
    list_dex
    |> Map.get("list")
    |> Enum.reduce_while(%{}, fn token_pair, acc ->
      if token_pair |> Map.get("address") != address, do: {:cont, acc}, else: {:halt, token_pair}
    end)
  end

  def common_token_pair_in_two_dexs(dex0, dex1) do
    dex0
    |> Map.get("list")
    |> Enum.reduce([], fn token_pair0, acc ->
      result =
        get_token_pair_from_token_ids(dex1 |> Map.get("list"), token_pair0)

      if not is_nil(result), do: acc ++ [result], else: acc
    end)
  end
end
