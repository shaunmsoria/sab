defmodule ListDex do


  defstruct name: "", list: []

  def get_list_dex_from_name(list_dex, name) when is_list(list_dex) and is_atom(name) do
      list_dex
      |> Enum.find(fn dex ->
          dex
          |> Map.get(:name) == name
      end)
  end

end
