defmodule ListDex do
  ## INFO defstruct deprecated
  defstruct name: "", list: []

  # def get_list_dex_from_name(list_dex, name) do
  #   list_dex
  #   |> Enum.find(fn dex ->
  #     dex
  #     |> Map.get("name") == name
  #   end)
  # end

  # def get_dex_token_pair_from_address(address) do
  #   with upcase_address <- String.upcase(address) do
  #     ConCache.get(:dex, "list_dex")
  #     |> Enum.reduce_while({}, fn dex_name, acc ->
  #       dex =
  #         ConCache.get(:dex, dex_name)

  #       found_token_pair_from_address =
  #         dex
  #         |> Enum.filter(fn full_token_pair ->
  #           {token_pair_key, token_pair} = full_token_pair

  #           upcase_address === String.upcase(token_pair_key)
  #         end)
  #         |> Enum.at(0)

  #       if is_nil(found_token_pair_from_address) do
  #         {:cont, acc}
  #       else
  #         {token_address, token_content} = found_token_pair_from_address
  #         {:halt, {:ok, {token_content, dex_name}}}
  #       end
  #     end)
  #   end
  # end

  # def token_pair_from_list_dex(list_dex, token_pair) do
  #   list_dex
  #   |> Enum.reduce_while(%{}, fn {_address, token_pair_searched}, acc ->
  #     if (String.equivalent?(
  #           token_pair["token0"]["address"],
  #           token_pair_searched["token0"]["address"]
  #         ) and
  #           String.equivalent?(
  #             token_pair["token1"]["address"],
  #             token_pair_searched["token1"]["address"]
  #           )) or
  #          (String.equivalent?(
  #             token_pair["token0"]["address"],
  #             token_pair_searched["token1"]["address"]
  #           ) and
  #             String.equivalent?(
  #               token_pair["token1"]["address"],
  #               token_pair_searched["token0"]["address"]
  #             )) do
  #       {:halt, token_pair_searched}
  #     else
  #       {:cont, acc}
  #     end
  #   end)
  # end

  # def is_address_in_list_dex?(list_dex, address) when is_binary(address) do
  #   list_dex
  #   |> Map.get("content")
  #   |> Enum.reduce_while(%{}, fn {address_pair, _content} = token_pair, acc ->
  #     if address_pair != address, do: {:cont, acc}, else: {:halt, token_pair}
  #   end)
  # end

  # def update_token_pair_price(token_pair, dex_name, price) do

  #   with :ok <-
  #          ConCache.update(:dex, dex_name, fn dex_content ->
  #            {:ok, %{dex_content | token_pair["address"] => %{token_pair | "price" => price}}}
  #          end) do
  #     {:ok, ConCache.get(:dex, dex_name) |> Map.get(token_pair["address"])}
  #   end
  # end
end
