defmodule Server.Router do
  use Plug.Router
  use GenServer

  plug :match
  plug :dispatch

  post "/hello" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts("Received POST request with body: #{body}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"message": "Hello, world!"}))
  end


  post "/event" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts("Received POST request with body: #{body}")

    event_raw = Jason.decode!(body)

      event = %{event: %{address: event_raw["address"]}}
      |> LogWritter.ipt("sx1 event")

    GenServer.cast(DexBot, {:swap_detected, event})



    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"message": "event received"}))
  end




  match _ do
    send_resp(conn, 404, "Oops, not found!")
  end
end
