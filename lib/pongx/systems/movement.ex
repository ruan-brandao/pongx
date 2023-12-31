defmodule Pongx.Systems.Movement do
  @moduledoc """
  System that controls movement for general game elements
  """
  @behaviour ECSx.System

  alias Pongx.Components.XPosition
  alias Pongx.Components.YPosition
  alias Pongx.Components.XVelocity
  alias Pongx.Components.YVelocity

  @game_world_width Application.compile_env(:pongx, :game_world_width)
  @game_world_height Application.compile_env(:pongx, :game_world_height)

  @impl ECSx.System
  def run do
    max_x_position = @game_world_width - 1
    max_y_position = @game_world_height - 1

    for {entity, x_velocity} <- XVelocity.get_all() do
      new_x_position =
        entity
        |> XPosition.get_one()
        |> calculate_new_position(x_velocity, max_x_position)

      XPosition.update(entity, new_x_position)
    end

    # Once the x-values are updated, do the same for the y-values
    for {entity, y_velocity} <- YVelocity.get_all() do
      new_y_position =
        entity
        |> YPosition.get_one()
        |> calculate_new_position(y_velocity, max_y_position)

      YPosition.update(entity, new_y_position)
    end

    :ok
  end

  defp calculate_new_position(current_position, velocity, max_position) do
    new_position = current_position + velocity
    new_position = Enum.min([new_position, max_position])
    Enum.max([new_position, 0])
  end
end
