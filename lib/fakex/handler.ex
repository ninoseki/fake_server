defmodule Fakex.Handler do
  def init(_type, conn, opts) do
    {:ok, conn, opts}
  end

  def handle(conn, opts) do
    opts[:behavior]
    |> check_behavior
    |> respond_accordingly(conn)
    |> format_response(conn, opts)
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp check_behavior(behavior) do
    case Fakex.Behavior.next_response(behavior) do
      {:ok, :no_more_actions} -> default_response
      {:ok, response} -> get_response(response)
    end
  end

  defp get_response(response) do
    case Fakex.Action.get(response) do    
      {:ok, response} -> response
      {:error, reason} -> {:error, reason}
    end
  end

  def default_response, do: %{response_code: 200, response_body: ~s<"status": "no more actions">}


  defp respond_accordingly(response, conn) do
    case :cowboy_req.reply(response[:response_code], [], response[:response_body], conn) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_response(:ok, conn, opts), do: {:ok, conn, opts}
  defp format_response({:error, reason}, conn, _opts), do: {:shutdown, conn, reason}
end