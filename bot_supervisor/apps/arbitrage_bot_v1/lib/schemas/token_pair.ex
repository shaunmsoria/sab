defmodule TokenPair do
  @derive {Jason.Encoder, only: [:token0, :token1, :address, :reserve]}
  defstruct token0: %Token{}, token1: %Token{}, address: "", reserve: ""
end
