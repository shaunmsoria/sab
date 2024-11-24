defmodule TokenContext do
  import Ecto.{Changeset, Query}

  def insert(params) do
    %Token{}
    |> Token.changeset(params)
    |> Repo.insert()
  end

  ##TODO to be tested
  def update(%Token{} = token, params) do
    token
    |> Token.changeset(params)
    |> Repo.update()
  end

  def test2() do
    from(t in "tokens", select: t.id)
    |> Repo.all()
  end

  def isTokenInMemory?(token_address_raw) do
    with token_address <- token_address_raw |> String.upcase() do
      if isTokenInStatedMemory?(token_address, "current_tokens") do
        true
      else
        isTokenInStatedMemory?(token_address, "new_tokens")
      end
    end
  end

  def isTokenInStatedMemory?(token_address, memory) do
    with tokens <- ConCache.get(:tokens, memory) do
      case is_nil(tokens) do
        true ->
          false

        false ->
          tokens
          |> Map.keys()
          |> Enum.member?(token_address)
      end
    end
  end
end
