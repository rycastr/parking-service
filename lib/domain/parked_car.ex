defmodule Domain.ParkedCar do
  defstruct [:license_plate, :check_in_date, :check_out_date]

  alias Ports.ParkedCarRepository

  @default_hour_value 10
  @default_first_hour_value 5
  @license_plate_regex ~r/^[A-Z]{3}[\-][0-9]{1}[0-9A-F]{1}[0-9]{2}$/

  def checkin(params) do
    with {:ok, parked_car} <- cast(params),
         :ok <- ParkedCarRepository.save(parked_car) do
      {:ok, parked_car}
    end
  end

  def checkout(parked_car_id, check_in_date, opts \\ []) do
    hour_value = Keyword.get(opts, :hour_value, @default_hour_value)
    first_hour_value = Keyword.get(opts, :first_hour_value, @default_first_hour_value)

    check_out_date = DateTime.utc_now()
    diff_time = DateTime.diff(check_out_date, check_in_date)

    with {:ok, _price} = result <- calcule_price(diff_time, hour_value, first_hour_value),
         :ok <- ParkedCarRepository.update(parked_car_id, %{check_out_date: check_out_date}) do
      result
    end
  end

  defp calcule_price(time, _hour_value, _first_hour_value) when time < 0,
    do: {:error, %Helpers.Error{reason: "invalid_check_in_date"}}

  defp calcule_price(time, _hour_value, first_hour_value) when time < 3600,
    do: {:ok, first_hour_value}

  defp calcule_price(time, hour_value, _first_hour_value) do
    hours = Integer.floor_div(time, 3600)
    price = hour_value * hours

    {:ok, price}
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
