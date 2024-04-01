defmodule Token do

  ##TODO Deprecated
  @derive {Jason.Encoder, only: [:name, :symbol, :address]}
  defstruct name: "", symbol: "", address: ""
end
