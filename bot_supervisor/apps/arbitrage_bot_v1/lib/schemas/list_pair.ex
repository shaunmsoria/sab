defmodule ListPair do
  defstruct list_pair0: [], list_pair1: []

  def get_list_pairs_from_id(list_pair, id) when is_list(list_pair) and is_binary(id) do
      list_pair
      |> Enum.find(fn pair ->
          pair |> Map.get("id") == id
      end)
  end

end
