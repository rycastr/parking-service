defmodule Domain.ParkedCar do
  defstruct [:license_plate, :check_in_date, :check_out_date]

  alias Ports.ParkedCarRepository

  @license_plate_regex ~r/^[A-Z]{3}[\-][0-9]{1}[0-9A-F]{1}[0-9]{2}$/

  def checkin(params) do
    with {:ok, parked_car} <- cast(params),
         :ok <- ParkedCarRepository.save(parked_car) do
      {:ok, parked_car}
    end
  end

  defp cast(params) do
    license_plate = Map.get(params, :license_plate)

    with {:ok, license_plate} <- validate_license_plate(license_plate) do
      parked_car = %__MODULE__{
        license_plate: license_plate,
        check_in_date: DateTime.utc_now()
      }

      {:ok, parked_car}
    end
  end

  defp validate_license_plate(nil),
    do: {:error, %Helpers.Error{reason: "license_plate_param_is_missing"}}

  defp validate_license_plate(license_plate) do
    if is_bitstring(license_plate) and Regex.match?(@license_plate_regex, license_plate) do
      {:ok, license_plate}
    else
      {:error, %Helpers.Error{reason: "license_plate_param_is_invalid"}}
    end
  end
end
