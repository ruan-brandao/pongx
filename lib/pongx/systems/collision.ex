defmodule Pongx.Systems.Collision do
  @moduledoc """
  Documentation for Collision system.
  """
  @behaviour ECSx.System

  alias Pongx.SystemUtils
  alias Pongx.Components.Score
  alias Pongx.Components.XVelocity
  alias Pongx.Components.YVelocity

  @impl ECSx.System
  def run do
    # Only balls have X Velocity
    balls = XVelocity.get_all()

    Enum.each(balls, &collide_if_needed(&1))
  end

  defp collide_if_needed({ball, current_x_velocity}) do
    # Only paddles have scores
    paddles = Score.get_all()

    Enum.each(paddles, fn {paddle, _} ->
      if SystemUtils.distance_between(paddle, ball) < 1 do
        current_x_velocity
        current_y_velocity = YVelocity.get_one(ball)

        XVelocity.update(ball, current_x_velocity * -1)
        YVelocity.update(ball, current_y_velocity * -1)
      end
    end)
  end
end
