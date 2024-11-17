defmodule StateConstructor do
  import Compute
  alias LogWritter, as: LW
  alias ListDex, as: LD

  @dexs Libraries.dexs()
  @tokens Libraries.tokens()
  @balancer Libraries.balancer()

  def run(limit \\ nil) do
    ConCache.put(:tokens, "should_refresh?", false)

    with {:ok, state} <- extract_list_pairs(limit) do
      ConCache.put(:tokens, "should_refresh?", true)
      {:ok, state}
    else
      ## if state not constructed because insufficient computation units / use another node provider ?
      error ->
        ConCache.put(:tokens, "should_refresh?", true)
        {:error, error}
    end
  end

  def reinitialise_state(state) do
    with list_dex <- ConCache.get(:dex, "list_dex") do
      list_dex
      |> Enum.map(fn dex_name ->
        dex_state = ListDex.get_list_dex_from_name(state, dex_name)

        dex_content =
          dex_state
          |> Map.get("content")

        ConCache.put(:dex, dex_name, dex_content)
      end)
    end

    {:ok, state}
  end

  def extract_list_pairs(limit) do
    list_dex_names = inspect(ConCache.get(:dex, "list_dex"))

    with {:ok, _tokens} <- fetch_tokens(),
         {:ok, state_file} <- state_file(),
         {:ok, state} <- maybe_build_state(state_file, ConCache.get(:system, :new_start)),
         {:ok, state_in_concache} <- reinitialise_state(state) do
      ConCache.put(:system, :new_start, false)

      LW.ipt("sx1 state first initialise from state file for dexs: #{list_dex_names}")

      {:ok, state}
    else
      {:initialise, _reason} ->
        with {:ok, new_state} <- build_state(%{}, limit) do
          LW.ipt("sx1 state initialised for dexs: #{list_dex_names}")
          {:ok, new_state}
        end

      {:rebuild, state} ->
        with {:ok, new_state} <- build_state(state, limit) do
          LW.ipt("sx1 state rebuilt for dexs: #{list_dex_names}")
          {:ok, new_state}
        end
    end
  end

  def maybe_build_state(state, true), do: {:ok, state}
  def maybe_build_state(state, false), do: {:rebuild, state}

  def build_state(initialised_state, limit) do
    with {:ok, new_state_without_status, current_tokens, new_tokens_for_processing} <-
           build_state_without_status(initialised_state, limit),
         {:ok, state_with_status} <- add_status_to_state(new_state_without_status),
         {:ok, new_state} <- reinitialise_state(state_with_status),
         {:ok, _file} <- write_state_file(new_state),
         {:ok, updated_tokens} <-
           update_tokens_with_new_tokens(current_tokens, new_tokens_for_processing),
         :ok <- ConCache.put(:system, :new_start, false) do
      {:ok, new_state}
    end
  end

  def build_state_without_status(state, limit) do
    with current_tokens <- ConCache.get(:tokens, "current_tokens"),
         {:ok, new_tokens_for_processing} <- fetch_new_tokens(limit),
         tokens <- Map.merge(current_tokens, new_tokens_for_processing) do
      new_state =
        ConCache.get(:dex, "list_dex")
        |> Enum.map(fn dex_key ->
          %{
            "name" => dex_key,
            "content" =>
              @dexs
              |> Map.get(dex_key)
              |> dex_token_pair_state_constructor(state, limit, tokens)
          }
        end)

      LogWritter.ipt("sx1 state construction pre status finished")

      {:ok, new_state, current_tokens, new_tokens_for_processing}
    end
  end

  def add_status_to_state(state_without_status) do
    state_with_status =
      ConCache.get(:dex, "list_dex")
      |> Enum.map(fn dex_key ->
        %{
          "name" => dex_key,
          "content" =>
            state_without_status
            |> LD.get_list_dex_from_name(dex_key)
            |> Map.get("content")
            |> Enum.reduce(%{}, fn token_pair, acc2 ->
              Map.merge(
                acc2,
                set_token_pair_status(token_pair, state_without_status, dex_key)
              )
            end)
        }
      end)

    {:ok, state_with_status}
  end

  def set_token_pair_status(
        {_token_pair_address, %{"status" => _status}} = token_pair,
        _state,
        _current_list_dex_name
      ),
      do: token_pair

  def set_token_pair_status(
        {token_pair_address, token_pair_content} = token_pair,
        state,
        current_list_dex_name
      ) do
    with list_dex_names_to_check <-
           ConCache.get(:dex, "list_dex")
           |> Enum.filter(fn list_dex_name -> list_dex_name != current_list_dex_name end) do
      token_pair_status =
        list_dex_names_to_check
        |> Enum.reduce_while("inactive", fn dex_name, acc ->
          %{"content" => dex_searched_content} =
            LD.get_list_dex_from_name(state, dex_name)

          test_result =
            LD.token_pair_from_list_dex(dex_searched_content, token_pair_content)

          # |> IO.inspect(label: "sx1 test_result")

          case test_result do
            %{"address" => _address} -> {:halt, "active"}
            %{} -> {:cont, acc}
          end
        end)

      %{token_pair_address => Map.merge(token_pair_content, %{"status" => token_pair_status})}
    end
  end

  def write_state_file(state) do
    state_jason =
      state |> Jason.encode!()

    with {:ok, file} <-
           File.open(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/state.json",
             [:write]
           ),
         :ok <-
           IO.binwrite(file, state_jason),
         :ok <- File.close(file) do
      {:ok, file}
    end
  end

  def state_file() do
    with {:ok, file} <-
           File.open(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/state.json",
             [:read]
           ),
         body <- IO.binread(file, :eof),
         :ok <- File.close(file),
         true <- body != :eof do
      {:ok, body |> Jason.decode!()}
    else
      {:error, :enoent} ->
        {:initialise, :enoent}

      {:error, error} ->
        error |> LogWritter.ipt("state_file error: #{error}")
        {:initialise, error}

      false ->
        {:initialise, :eof}
    end
  end

  def dex_token_pair_state_constructor(dex, state, limit, tokens) do
    with name <- dex |> Map.get("name"),
         factory_address <-
           dex
           |> Map.get("factory"),
         list_dex <-
           state
           |> ListDex.get_list_dex_from_name(name),
         {:ok, map_token_pair} <- extract_map_token_pair(list_dex),
         :ok <- ConCache.put(:dex, name, map_token_pair) do
      {processed_token_pair, _count} =
        tokens
        |> Enum.reduce({%{}, 1}, fn token, acc ->
          {token_pair_list, count} = acc

          {_examined_tokens, reduced_tokens} =
            tokens
            |> Enum.split(count)

          additional_token_pair_list =
            reduced_tokens
            |> Enum.reduce(%{}, fn token_checked, acc2 ->
              Map.merge(
                acc2,
                valid_token_response(
                  exist_token_pair(factory_address, map_token_pair, token, token_checked)
                )
              )
            end)

          {Map.merge(token_pair_list, additional_token_pair_list), count + 1}
        end)

      processed_token_pair
    end
  end

  def update_tokens_with_new_tokens(current_tokens, new_processed_tokens) do
    with true <- new_processed_tokens === %{} do
      {:ok, current_tokens}
    else
      false ->
        with new_current_tokens <- Map.merge(current_tokens, new_processed_tokens),
             {:ok, file} <- write_tokens_file(new_current_tokens),
             :ok <- ConCache.put(:tokens, "current_tokens", new_current_tokens),
             new_tokens <- ConCache.get(:tokens, "new_tokens"),
             updated_new_tokens <- Map.drop(new_tokens, new_processed_tokens |> Map.keys()),
             :ok <- ConCache.put(:tokens, "new_tokens", updated_new_tokens) do
          LogWritter.ipt("sx1 #{inspect(new_processed_tokens)} added to the current tokens")
          {:ok, new_current_tokens}
        end
    end
  end

  def valid_token_response({:error, message}) do
    {:error, message} |> LogWritter.ipt("sx1 error:")

    %{}
  end

  def valid_token_response(token_pair), do: token_pair

  def extract_map_token_pair(%{"content" => map_token_pair}), do: {:ok, map_token_pair}
  def extract_map_token_pair(nil), do: {:ok, nil}

  def write_tokens_file(tokens) do
    tokens_jason =
      tokens |> Jason.encode!()

    with {:ok, file} <-
           File.open(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/tokens.json",
             [:write]
           ),
         :ok <-
           IO.binwrite(file, tokens_jason),
         :ok <- File.close(file) do
      {:ok, file}
    end
  end

  def fetch_tokens() do
    with {:ok, file} <-
           File.open(
             "/home/server/Programs/sab/bot_supervisor/apps/arbitrage_bot_v1/lib/libraries/json/tokens.json",
             [:read]
           ),
         body <- IO.binread(file, :eof),
         :ok <- File.close(file),
         true <- body != :eof do
      tokens = body |> Jason.decode!()

      ConCache.put(:tokens, "current_tokens", tokens)
      {:ok, tokens}
    else
      _ ->
        with tokens <- Libraries.tokens(),
             {:ok, file} <- write_tokens_file(tokens) do
          ConCache.put(:tokens, "current_tokens", tokens)
          {:ok, tokens}
        end
    end
  end

  def fetch_new_tokens(limit \\ nil) do
    with new_tokens <- ConCache.get(:tokens, "new_tokens") do
      case new_tokens do
        nil ->
          {:ok, %{}}

        new_tokens ->
          requested_tokens =
            case limit do
              nil ->
                new_tokens

              limit_value ->
                new_tokens
                |> Enum.slice(0, limit_value)
                |> Enum.reduce(%{}, fn {name, token}, acc ->
                  acc
                  |> Map.merge(%{name => token})
                end)
            end

          # LogWritter.ipt(
          #   "sx1 requested_tokens: #{inspect(requested_tokens |> Map.values() |> Enum.at(0) |> Map.get("symbol"))}"
          # )

          {:ok, requested_tokens}
      end
    end
  end

  def exist_token_pair(_factory_address, _map_token_pair, _token, %{}), do: %{}

  def exist_token_pair(factory_address, nil, token, token_checked) do
    {_name, token_value} = token
    {_name_checked, token_value_checked} = token_checked

    with {:ok, pair_address} <-
           Compute.get_pair_address(
             factory_address,
             token_value["address"],
             token_value_checked["address"]
           ) do
      if not String.equivalent?(pair_address, "0x0000000000000000000000000000000000000000") do
        %{
          pair_address =>
            %{
              "token0" => token_value,
              "token1" => token_value_checked,
              "address" => pair_address
            }
            |> Map.merge(get_token_pair_price(pair_address))
        }
      else
        %{}
      end
    end
  end

  def exist_token_pair(factory_address, map_token_pair, token, token_checked) do
    {_name, token_value} = token
    {_name_checked, token_value_checked} = token_checked

    with %{} <-
           ListDex.token_pair_from_list_dex(map_token_pair, %{
             "token0" => token_value,
             "token1" => token_value_checked
           }) do
      with {:ok, pair_address} <-
             Compute.get_pair_address(
               factory_address,
               token_value["address"],
               token_value_checked["address"]
             ) do
        if not String.equivalent?(pair_address, "0x0000000000000000000000000000000000000000") do
          %{
            pair_address =>
              %{
                "token0" => token_value,
                "token1" => token_value_checked,
                "address" => pair_address
              }
              |> Map.merge(get_token_pair_price(pair_address))
          }
        else
          %{}
        end
      end
    else
      {_address, token_pair} ->
        %{
          token_pair["address"] =>
            token_pair |> Map.merge(get_token_pair_price(token_pair["address"]))
        }
    end
  end

  def get_token_pair_price(token_pair) do
    # %{"price" => Compute.calculate_price(token_pair)}
    %{"price" => 0}
  end
end
