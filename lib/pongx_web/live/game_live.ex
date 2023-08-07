defmodule PongxWeb.GameLive do
  use PongxWeb, :live_view

  alias Pongx.Components.XPosition
  alias Pongx.Components.YPosition
  alias Pongx.Components.Score
  alias Pongx.Components.ImageFile
  alias Pongx.Components.PlayerSpawned

  def mount(_params, %{"player_token" => token} = _session, socket) do
    game_world_width = Application.fetch_env!(:pongx, :game_world_width)
    game_world_height = Application.fetch_env!(:pongx, :game_world_height)
    player = Pongx.Players.get_player_by_session_token(token)
    ball_entity_id = Ecto.UUID.generate()

    socket =
      socket
      |> assign(player_entity: player.id)
      |> assign(ball_entity: ball_entity_id)
      |> assign(keys: MapSet.new())
      |> assign(screen_height: game_world_height, screen_width: game_world_width)
      |> assign(x_coord: nil, y_coord: nil, current_score: nil)
      |> assign(ball_x_coord: nil, ball_y_coord: nil)
      |> assign_loading_state()

    if connected?(socket) do
      ECSx.ClientEvents.add(player.id, :spawn_paddle)
      ECSx.ClientEvents.add(ball_entity_id, :spawn_ball)
      # The first load will now have additional responsibilities
      send(self(), :first_load)
    end

    {:ok, socket}
  end

  defp assign_loading_state(socket) do
    assign(socket,
      x_coord: nil,
      y_coord: nil,
      current_score: nil,
      ball_x_coord: nil,
      ball_y_coord: nil,
      # This new assign will control whether the loading screen is shown
      loading: true
    )
  end

  def handle_info(:first_load, socket) do
    # Don't start fetching components until after spawn is complete!
    :ok = wait_for_spawn(socket.assigns.player_entity, socket.assigns.ball_entity)

    socket =
      socket
      |> assign_player_paddle()
      |> assign_ball()
      |> assign(loading: false)

    # We want to keep up-to-date on this info
    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_player_paddle()
      |> assign_ball()

    {:noreply, socket}
  end

  defp wait_for_spawn(player_entity, ball_entity) do
    if PlayerSpawned.exists?(player_entity) and PlayerSpawned.exists?(ball_entity) do
      :ok
    else
      Process.sleep(10)
      wait_for_spawn(player_entity, ball_entity)
    end
  end

  defp assign_player_paddle(socket) do
    # This will run every 50ms to keep the client assigns updated
    x = XPosition.get_one(socket.assigns.player_entity)
    y = YPosition.get_one(socket.assigns.player_entity)
    score = Score.get_one(socket.assigns.player_entity)
    image = ImageFile.get_one(socket.assigns.player_entity)

    assign(socket, x_coord: x, y_coord: y, current_score: score, player_paddle_image: image)
  end

  defp assign_ball(socket) do
    x = XPosition.get_one(socket.assigns.ball_entity)
    y = YPosition.get_one(socket.assigns.ball_entity)
    image = ImageFile.get_one(socket.assigns.ball_entity)

    assign(socket, ball_x_coord: x, ball_y_coord: y, ball_image: image)
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
      <p>Player paddle position: <%= inspect({@x_coord, @y_coord}) %></p>
      <p>Ball position: <%= inspect({@ball_x_coord, @ball_y_coord}) %></p>
      <p>Score: <%= @current_score %></p>
      <br />
      <svg viewBox={"0 0 #{@screen_width} #{@screen_height}"} preserveAspectRatio="xMinYMin slice">
        <rect width={@screen_width} height={@screen_height} fill="#9db2bf" />

        <%= if @loading do %>
          <text
            x={div(@screen_width, 2)}
            y={div(@screen_height, 2)}
            style="font: 1px serif; color: #dde6ed"
          >
            Loading...
          </text>
        <% else %>
          <image
            x={@x_coord}
            y={@y_coord}
            width="5"
            height="5"
            href={~p"/images/#{@player_paddle_image}"}
          />

          <image
            x={@ball_x_coord}
            y={@ball_y_coord}
            width="1"
            height="1"
            href={~p"/images/#{@ball_image}"}
          />
        <% end %>
      </svg>
    </div>
    """
  end
end
