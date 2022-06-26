defmodule Ports.ParkedCarRepository do
  alias Domain.ParkedCar

  @callback save(parked_car :: ParkedCar.t()) :: :ok | {:error, Helpers.Error.t()}
  @callback update(parked_car_id :: String.t(), updates :: map()) :: :ok | {:error, Helpers.Error.t()}

  def save(parked_car), do: impl().save(parked_car)
  def update(parked_car_id, updates), do: impl().update(parked_car_id, updates)

  defp impl, do: Application.get_env(:parking, :parked_car_repository)
end
