defmodule Pongx.Systems.ClientEventHandler do
  @moduledoc """
  Documentation for ClientEventHandler system.
  """
  @behaviour ECSx.System

  alias Pongx.Components.Score
  alias Pongx.Components.XPosition
  alias Pongx.Components.YPosition
  alias Pongx.Components.XVelocity
  alias Pongx.Components.YVelocity
  alias Pongx.Components.ImageFile
  alias Pongx.Components.PlayerSpawned

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_paddle}) do
    Score.add(player, 0)
    # paddles only move vertically, so they don't need an XVelocity
    XPosition.add(player, 1)
    YPosition.add(player, 25)
    YVelocity.add(player, 0)

    ImageFile.add(player, "paddle.svg")
    PlayerSpawned.add(player)
  end

  defp process_one({ball, :spawn_ball}) do
    XPosition.add(ball, 45)
    YPosition.add(ball, 25)
    XVelocity.add(ball, -1)
    YVelocity.add(ball, 1)

    ImageFile.add(ball, "ball.svg")
    PlayerSpawned.add(ball)
  end

  defp process_one({player, {:move, :north}}), do: YVelocity.update(player, -1)
  defp process_one({player, {:move, :south}}), do: YVelocity.update(player, 1)
  defp process_one({player, :stop_move}), do: YVelocity.update(player, 0)
end
