defmodule Pongx.Systems.Collision do
  @moduledoc """
  Documentation for Collision system.
  """
  @behaviour ECSx.System

  alias Pongx.Components.YPosition
  alias Pongx.SystemUtils
  alias Pongx.Components.Score
  alias Pongx.Components.XVelocity
  alias Pongx.Components.YVelocity
  alias Pongx.Components.YPosition

  @game_world_height Application.compile_env(:pongx, :game_world_height)

  @impl ECSx.System
  def run do
    # Only balls have X Velocity
    balls = XVelocity.get_all()

    Enum.each(balls, &collide_if_needed(&1))
  end

  defp collide_if_needed({ball, current_x_velocity}) do
    current_y_velocity = YVelocity.get_one(ball)

    # Bounces the ball back if it touches the top or bottom of the screen
    max_y_position = @game_world_height - 1
    y_position = YPosition.get_one(ball)

    if y_position in [0, max_y_position] do
      YVelocity.update(ball, current_y_velocity * -1)
    end

    # Only paddles have scores
    paddles = Score.get_all()

    Enum.each(paddles, fn {paddle, _} ->
      if SystemUtils.distance_between(paddle, ball) < 1 do
        XVelocity.update(ball, current_x_velocity * -1)
      end
    end)
  end
end
