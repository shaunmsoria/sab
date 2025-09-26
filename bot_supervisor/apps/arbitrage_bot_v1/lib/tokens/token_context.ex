defmodule TokenContext do
  import Compute
  import Ecto.{Changeset, Query}
  alias TokenSearch, as: TS
  alias TokenContext, as: TC
  alias LogWritter, as: LW

  def insert(params) do
    %Token{}
    |> Token.changeset(params)
    |> Repo.insert()
  end

  def update(%Token{} = token, params) do
    token
    |> Token.changeset(params)
    |> Repo.update()
  end

  def maybe_add_token(token_address) do
    with true <- String.contains?(token_address |> inspect(), "<<") do
      {:error, "token with address #{token_address} couldn't be retrieved"}
    else
      false ->
        case TS.with_address(token_address)
             |> Repo.one() do
          nil ->
            with {:ok, symbol, name, decimals} <-
                   token_address
                   |> get_contract_for_token_address(),
                 {:ok, token} <-
                   %{
                     symbol: symbol,
                     name: name,
                     address: token_address,
                     upcase_address: token_address |> String.upcase(),
                     decimals: decimals
                   }
                   |> LW.ipt("sx1 before LW.ipt")
                   |> TC.insert()
                   |> LW.ipt("sx1 TC.insert()") do
              {:ok, token}
            end

          %Token{} = token ->
            {:ok, token}
        end
    end
  end

  def get_contract_for_token_address(token_address) do
    with symbol_result <-
           (try do
              token_address |> token_erc20(:symbol)
            rescue
              e ->
                {:ok, token_address}
            end),
         name_result <-
           (try do
              token_address |> token_erc20(:name)
            rescue
              e ->
                {:ok, token_address}
            end),
         decimals_result <-
           (try do
              token_address |> token_erc20(:decimals)
            rescue
              e ->
                {:ok, 0}
            end) do
      {:ok, sanitise_param(symbol_result), sanitise_param(name_result),
       sanitise_param(decimals_result, :decimals)}
      |> LW.ipt("sx1 get_contract_for_token_address")
    end
  end

  def sanitise_param({:ok, param}) when is_binary(param) do
    case param do
      "0x" ->
        nil

      param ->
        split_param = param |> String.slice(0..15) |> inspect() |> String.trim("\"")
    end
  end

  def sanitise_param(_), do: nil

  def sanitise_param({:ok, param}, :decimals) when is_integer(param), do: param
  def sanitise_param(_, :decimals), do: 0


end
