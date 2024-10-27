defmodule Token do

  ##INFO Deprecated
  @derive {Jason.Encoder, only: [:name, :symbol, :address]}
  defstruct name: "", symbol: "", address: ""


  def isTokenInMemory?(token_address_raw) do


    with token_address <- token_address_raw |> String.upcase(),
    tokens <- ConCache.get(:tokens, "new_tokens"),
    tokens_address <-
      tokens
    |> Map.values()
    |> Enum.map(fn token -> token["address"] |> String.upcase() end)  do
      tokens_address |> Enum.member?(token_address)
    end
  end
end
