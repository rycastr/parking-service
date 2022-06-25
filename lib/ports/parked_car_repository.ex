defmodule Ports.ParkedCarRepository do
  alias Domain.ParkedCar

  @callback save(parkedCar :: ParkedCar.t()) :: :ok | {:error, Helpers.Error.t()}

  def save(parkedCar), do: impl().save(parkedCar)

  defp impl, do: Application.get_env(:parking, :parked_car_repository)
end
