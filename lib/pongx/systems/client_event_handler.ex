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

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_paddle}) do
    Score.add(player, 0)
    XPosition.add(player, 0)
    YPosition.add(player, 25)
    XVelocity.add(player, 0)
    YVelocity.add(player, 0)
  end

  defp process_one({player, {:move, :north}}), do: YVelocity.update(player, -1)
  defp process_one({player, {:move, :south}}), do: YVelocity.update(player, 1)
  defp process_one({player, :stop_move}), do: YVelocity.update(player, 0)
end
