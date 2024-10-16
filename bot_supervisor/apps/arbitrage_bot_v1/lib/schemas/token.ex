defmodule Token do

  ##INFO Deprecated
  @derive {Jason.Encoder, only: [:name, :symbol, :address]}
  defstruct name: "", symbol: "", address: ""


  def isTokenInMemory?(token_address) do
    with tokens <- ConCache.get(:tokens, "new_tokens"),
    tokens_address <- tokens |> Map.values() |> Enum.map(fn token -> token.address end) do
      tokens_address |> Enum.member?(token_address)
    end
  end
end
