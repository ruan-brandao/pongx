defmodule PongxWeb.GameLive do
  use PongxWeb, :live_view

  # alias Pongx.Components.XPosition
  alias Pongx.Components.YPosition
  alias Pongx.Components.Score

  def mount(_params, %{"player_token" => token} = _session, socket) do
    player = Pongx.Players.get_player_by_session_token(token)

    socket =
      socket
      |> assign(player_entity: player.id)
      |> assign(keys: MapSet.new())
      |> assign(y_coord: nil, current_score: nil)

    if connected?(socket) do
      ECSx.ClientEvents.add(player.id, :spawn_paddle)
      :timer.send_interval(50, :load_player_info)
    end

    {:ok, socket}
  end

  def handle_info(:load_player_info, socket) do
    # This will run every 50ms to keep the client assigns updated
    y = YPosition.get_one(socket.assigns.player_entity)
    score = Score.get_one(socket.assigns.player_entity)

    {:noreply, assign(socket, y_coord: y, current_score: score)}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      # Already holding this key - do nothing
      {:noreply, socket}
    else
      # We only want to add a client event if the key is defined by the `keydown/1` helper below
      maybe_add_client_event(socket.assigns.player_entity, key, &keydown/1)
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    # We don't have to worry about duplicate keyup events
    # But once again, we will only add client events for keys that actually do something
    maybe_add_client_event(socket.assigns.player_entity, key, &keyup/1)
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp maybe_add_client_event(player_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(player_entity, event)
    end
  end

  defp keydown(key) when key in ~w(w W ArrowUp), do: {:move, :north}
  defp keydown(key) when key in ~w(s S ArrowDown), do: {:move, :south}
  defp keydown(_key), do: :noop

  defp keyup(key) when key in ~w(w W ArrowUp), do: :stop_move
  defp keyup(key) when key in ~w(s S ArrowDown), do: :stop_move
  defp keyup(_key), do: :noop

  def render(assigns) do
    ~H"""
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup">
      <p>Game running</p>
      <p>Player ID: <%= @player_entity %></p>
      <p>Player paddle position: <%= @y_coord %></p>
      <p>Score: <%= @current_score %></p>
    </div>
    """
  end
end
