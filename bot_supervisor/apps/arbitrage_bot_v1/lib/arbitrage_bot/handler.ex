defmodule DexBot.Handler do
  use W3WS.Handler
  use GenServer

  @impl W3WS.Handler

  @event %W3WS.Env{
    event: %W3WS.Event{
      # address: "0x2B08A6aAfB04447FFE19BE24d2015d42C00165Bc",
      # address: "0x4329412f58161141eb3d86c5c9a406d99020b518",
      address: "0x00001bea43608c5ee487f82b773af8bd7cb20a6f",
      # address: "0x1b882ce4976b23d8a393de71524f38912963ba05",
      block_hash: "0x754ca9505edad29c2e32ded679baec13f0ae46c8a27a525e4dc1a100b9e13fbd",
      block_number: 19_260_153,
      data: %{
        "amount0In" => 0,
        "amount0Out" => 153_617_137_728_786_375,
        "amount1In" => 3_032_911_509_286_053_043,
        "amount1Out" => 0,
        "sender" => "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad",
        "to" => "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad"
      },
      fields: [
        %{name: "sender", type: :address, indexed: true},
        %{name: "amount0In", type: {:uint, 256}, indexed: false},
        %{name: "amount1In", type: {:uint, 256}, indexed: false},
        %{name: "amount0Out", type: {:uint, 256}, indexed: false},
        %{name: "amount1Out", type: {:uint, 256}, indexed: false},
        %{name: "to", type: :address, indexed: true}
      ],
      log_index: 346,
      name: "Swap",
      removed: false,
      topics: [
        "0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822",
        "0x0000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad",
        "0x0000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad"
      ],
      transaction_hash: "0x5b5108e4e1caea7e9e6832426ea214e0ca98a4c3035eebae0286575583dfc7da",
      transaction_index: 143
    },
    context: %{chain_id: 1},
    decoded?: true,
    jsonrpc: "2.0",
    method: "eth_subscription",
    raw: %W3WS.RawEvent{
      address: "0x1b882ce4976b23d8a393de71524f38912963ba05",
      block_hash: "0x754ca9505edad29c2e32ded679baec13f0ae46c8a27a525e4dc1a100b9e13fbd",
      block_number: "0x125e2f9",
      data:
        "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a1710f2da3064b30000000000000000000000000000000000000000000000000221c1f90dbc8fc70000000000000000000000000000000000000000000000000000000000000000",
      log_index: "0x15a",
      removed: false,
      topics: [
        "0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822",
        "0x0000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad",
        "0x0000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad"
      ],
      transaction_hash: "0x5b5108e4e1caea7e9e6832426ea214e0ca98a4c3035eebae0286575583dfc7da",
      transaction_index: "0x8f"
    },
    subscription: "0x1a4dd7d0606fa307842bbaaa5ce1c95d"
  }

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_event(
        %Env{
          decoded?: true,
          event: %Event{name: "Swap", data: _data}
        } = event,
        _state
      ) do
    event |> IO.inspect(label: "sx1 event filtered")

    GenServer.cast(DexBot, {:swap_detected, event})
  end

  # def handle_event(
  #       %Env{
  #         decoded?: true,
  #         event: event
  #         },
  #       _state
  #     ) do
  #  event.name |> IO.inspect(label: "sx1 event.name")
  # end

  def handle_event(
        _event,
        _state
      ) do
    # event |> IO.inspect(label: "sx1 any event")
    nil
  end

  ## command to execute:
  ## DexBot.Handler.test()
  def test() do
    GenServer.cast(DexBot, {:swap_detected, @event})
  end
end
