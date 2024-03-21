defmodule Token do
  @derive {Jason.Encoder, only: [:name, :symbol, :address]}
  defstruct name: "", symbol: "", address: ""
end
