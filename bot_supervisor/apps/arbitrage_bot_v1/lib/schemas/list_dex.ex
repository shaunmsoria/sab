defmodule ListDex do


  defstruct name: "", list: []

  def get_list_dex_from_name(list_dex, name) when is_list(list_dex) and is_atom(name) do
      list_dex
      |> Enum.find(fn dex ->
          dex
          |> Map.get(:name) == name
      end)
  end

  def get_list_dex_from_address(state, address) when is_list(state) and is_binary(address) do
      state
      |> Enum.reduce_while(%{}, fn list_dex, acc ->
        if is_address_in_list_dex?(list_dex, address) == false, do: {:cont, acc}, else: {:halt, list_dex}
      end)
  end

  def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
    list_dex
    |> Map.get(:list)
    |> Enum.reduce_while(false, fn token_pair, acc ->
      # list_dex |> Map.get(:name) |> IO.inspect(label: "sx1 list_dex name")
      # token_pair |> Map.get("id") |> IO.inspect(label: "sx1 token_pair")
      # address |> IO.inspect(label: "sx1 address")
      # (token_pair |> Map.get("id") != address) |> IO.inspect(label: "sx1 test result")

      if token_pair |> Map.get("id") != address, do: {:cont, acc}, else: {:halt, true}
    end)
  end
end
