defmodule Server.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  post "/hello" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts("Received POST request with body: #{body}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"message": "Hello, world!"}))
  end

  match _ do
    send_resp(conn, 404, "Oops, not found!")
  end
end
