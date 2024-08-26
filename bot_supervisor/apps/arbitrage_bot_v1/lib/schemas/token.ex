defmodule Token do

  ##INFO Deprecated
  @derive {Jason.Encoder, only: [:name, :symbol, :address]}
  defstruct name: "", symbol: "", address: ""
end
