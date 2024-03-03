defmodule ListPair do

  ##TODO ListPair is now a list of %{name: x, list: y}
  ##TODO restruct ListPair accordingly

  defstruct list_pair0: [], list_pair1: []

  def get_list_pairs_from_id(list_pair, id) when is_list(list_pair) and is_binary(id) do
      list_pair
      |> Enum.find(fn pair ->
          pair |> Map.get("id") == id
      end)
  end

end
