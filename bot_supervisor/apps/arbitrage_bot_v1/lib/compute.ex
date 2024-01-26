defmodule Compute do

  def get_pair_address(factory_address, token0_address, token1_address) do
    DexContract.get_pair(token0_address, token1_address)
    |> Ethers.call(to: factory_address)
  end


  ## macro this?
  # def pair_contract(pair_address, function_contract) do
  #     LiquidityPoolContract.function_contract()
  #   |> Ethers.call(to: pair_address)
  # end

  # def pair_contract(pair_address, function_contract, params) do
  #   LiquidityPoolContract.function_contract(params)
  #   |> Ethers.call(to: pair_address)
  # end

end
