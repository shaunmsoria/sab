defmodule ListDex do


  defstruct name: "", list: []

  def get_list_dex_from_name(list_dex, name) when is_list(list_dex) and is_atom(name) do
      list_dex
      |> Enum.find(fn dex ->
          dex
          |> Map.get(:name) == name
      end)
  end

  def get_dex_token_pair_from_address(state, address) when is_list(state) and is_binary(address) do
      state
      |> Enum.reduce_while(%{}, fn list_dex, acc ->
        result_dex_token_pair =
          is_address_in_list_dex?(list_dex, address)

        if result_dex_token_pair == %{}, do: {:cont, acc}, else: {:halt, result_dex_token_pair}
      end)
  end

  def get_token_pair_from_token_ids(list_dex, token_pair) when is_list(list_dex) do
    with id0 <- token_pair |> Map.get("token0") |> Map.get("id"),
    id1 <- token_pair |> Map.get("token1") |> Map.get("id") do
      _list_token_pairs =
          list_dex
          |> Enum.reduce_while(%{}, fn token_pair_searched, acc ->
            token_pair_searched
            |> Map.get("token0")
            |> Map.get("symbol")
            |> IO.inspect(label: "sx1 token0 > symbol")

            token_pair_searched
            |> Map.get("token1")
            |> Map.get("symbol")
            |> IO.inspect(label: "sx1 token1 > symbol")

            searched_id0 =
              token_pair_searched |> Map.get("token0") |> Map.get("id")
              # |> IO.inspect(label: "sx1 searched_id0")

            searched_id1 =
              token_pair_searched |> Map.get("token1") |> Map.get("id")
              # |> IO.inspect(label: "sx1 searched_id1")

              # id0
              # |> IO.inspect(label: "sx1 id0")

              # id1
              # |> IO.inspect(label: "sx1 id1")

              # (String.equivalent?(searched_id0, id0) and String.equivalent?(searched_id1, id1))
              # |> IO.inspect(label: "sx1 String.equivalent?(searched_id0, id0) and String.equivalent?(searched_id1, id1)")

              # (String.equivalent?(searched_id1, id0) and String.equivalent?(searched_id0, id1))
              # |> IO.inspect(label: "sx1 String.equivalent?(searched_id1, id0) and String.equivalent?(searched_id0, id1)")

              # String.equivalent?(searched_id0, id0)
              # |> IO.inspect(label: "sx1 string.equivalent?(searched_id0, id0)")

              # String.equivalent?(searched_id1, id1)
              # |> IO.inspect(label: "sx1 string.equivalent?(searched_id1, id1)")

              # String.equivalent?(searched_id1, id0)
              # |> IO.inspect(label: "sx1 string.equivalent?(searched_id1, id0)")

              # String.equivalent?(searched_id0, id1)
              # |> IO.inspect(label: "sx1 string.equivalent?(searched_id0, id1)")

            # if (searched_id0 == id0 and searched_id1 == id1) or (searched_id1 == id0 and searched_id0 == id1) do
            if (String.equivalent?(searched_id0, id0) and String.equivalent?(searched_id1, id1)) or (String.equivalent?(searched_id1, id0) and String.equivalent?(searched_id0, id1)) |> IO.inspect(label: "sx1 result") do
              {:halt, token_pair_searched}
              else
                {:cont, acc}
            end
          end)
    end
  end


  def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
    list_dex
    |> Map.get(:list)
    |> Enum.reduce_while(%{}, fn token_pair, acc ->

      # list_dex |> Map.get(:name) |> IO.inspect(label: "sx1 list_dex name")
      # token_pair |> Map.get("id") |> IO.inspect(label: "sx1 token_pair")
      # address |> IO.inspect(label: "sx1 address")
      # (token_pair |> Map.get("id") != address) |> IO.inspect(label: "sx1 test result")

      if token_pair |> Map.get("id") != address, do: {:cont, acc}, else: {:halt, token_pair}
    end)
  end

  # def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
  #   list_dex
  #   |> Map.get(:list)
  #   |> Enum.reduce_while(false, fn token_pair, acc ->
  #     list_dex |> Map.get(:name) |> IO.inspect(label: "sx1 list_dex name")
  #     token_pair |> Map.get("id") |> IO.inspect(label: "sx1 token_pair")
  #     address |> IO.inspect(label: "sx1 address")
  #     (token_pair |> Map.get("id") != address) |> IO.inspect(label: "sx1 test result")

  #     if token_pair |> Map.get("id") != address, do: {:cont, acc}, else: {:halt, true}
  #   end)
  # end
end
