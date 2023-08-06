defmodule Pongx.Systems.Movement do
  @moduledoc """
  System that controls movement for general game elements
  """
  @behaviour ECSx.System

  alias Pongx.Components.XPosition
  alias Pongx.Components.YPosition
  alias Pongx.Components.XVelocity
  alias Pongx.Components.YVelocity

  @impl ECSx.System
  def run do
    for {entity, x_velocity} <- XVelocity.get_all() do
      x_position = XPosition.get_one(entity)
      new_x_position = calculate_new_position(x_position, x_velocity)
      XPosition.update(entity, new_x_position)
    end

    # Once the x-values are updated, do the same for the y-values
    for {entity, y_velocity} <- YVelocity.get_all() do
      y_position = YPosition.get_one(entity)
      new_y_position = calculate_new_position(y_position, y_velocity)
      YPosition.update(entity, new_y_position)
    end

    :ok
  end

  defp calculate_new_position(current_position, velocity) do
    current_position + velocity
    # new_position = Enum.min([new_position, 45])

    # Enum.max([new_position, 0])
  end
end
