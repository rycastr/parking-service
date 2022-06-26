defmodule Domain.ParkedCarTest do
  use ExUnit.Case

  import Mox

  alias Domain.ParkedCar

  describe "checkin/1" do
    test "when receive a empty map it should return an error" do
      params = %{}

      result = ParkedCar.checkin(params)

      assert {:error, %Helpers.Error{reason: "license_plate_param_is_missing"}} = result
    end

    test "when receive a invalid license_plate param it should return an error" do
      params = %{
        license_plate: "invalid-plate"
      }

      result = ParkedCar.checkin(params)

      assert {:error, %Helpers.Error{reason: "license_plate_param_is_invalid"}} = result
    end

    test "when the car already checked-in it should return an error" do
      expect(
        Ports.MockParkedCarRepository,
        :save,
        fn _parked_car -> {:error, %Helpers.Error{reason: "check-in has already been done"}} end
      )

      params = %{
        license_plate: "AAA-9999"
      }

      result = ParkedCar.checkin(params)

      assert {:error, %Helpers.Error{reason: "check-in has already been done"}} = result
    end

    test "when the check-in was successful it should return a success result with a parked car" do
      expect(
        Ports.MockParkedCarRepository,
        :save,
        fn _parked_car -> :ok end
      )

      params = %{
        license_plate: "AAA-9999"
      }

      result = ParkedCar.checkin(params)

      assert {:ok, %ParkedCar{} = parked_car} = result
      assert parked_car.license_plate == params.license_plate
      assert not is_nil(parked_car.check_in_date)
      assert is_nil(parked_car.check_out_date)
    end
  end

  describe "checkout/1" do
    test "when check_in_date is greater than current date should return an error" do
      parked_car_id = "68004555-1a0d-4447-99ee-c5c6835086b1"
      check_in_date = DateTime.add(DateTime.utc_now(), 50000)

      result = ParkedCar.checkout(parked_car_id, check_in_date)

      assert {:error, %Helpers.Error{reason: "invalid_check_in_date"}} = result
    end

    test "when the parked car does not exist it should return an error" do
      expect(
        Ports.MockParkedCarRepository,
        :update,
        fn _parked_car_id, _update_values ->
          {:error, %Helpers.Error{reason: "parked_car_does_not_exist"}}
        end
      )

      parked_car_id = "68004555-1a0d-4447-99ee-c5c6835086b1"
      check_in_date = DateTime.add(DateTime.utc_now(), -1)

      result = ParkedCar.checkout(parked_car_id, check_in_date)

      assert {:error, %Helpers.Error{reason: "parked_car_does_not_exist"}} = result
    end

    test "when the parked car has already checked out" do
      expect(
        Ports.MockParkedCarRepository,
        :update,
        fn _parked_car_id, _update_values ->
          {:error, %Helpers.Error{reason: "parked_car_has_already_left"}}
        end
      )

      parked_car_id = "68004555-1a0d-4447-99ee-c5c6835086b1"
      check_in_date = DateTime.add(DateTime.utc_now(), -1)

      result = ParkedCar.checkout(parked_car_id, check_in_date)

      assert {:error, %Helpers.Error{reason: "parked_car_has_already_left"}} = result
    end

    test "when the checkout was successful and the parking time less than 1 hour should return the price of the first hour" do
      expect(
        Ports.MockParkedCarRepository,
        :update,
        fn _parked_car_id, _update_values -> :ok end
      )

      parked_car_id = "68004555-1a0d-4447-99ee-c5c6835086b1"
      check_in_date = DateTime.add(DateTime.utc_now(), -1)

      first_hour_value = 5

      result = ParkedCar.checkout(parked_car_id, check_in_date, first_hour_value: first_hour_value)

      assert {:ok, ^first_hour_value} = result
    end

    test "when checkout was successful and parking time longer than 1 hour should return hourly price calculation" do
      expect(
        Ports.MockParkedCarRepository,
        :update,
        fn _parked_car_id, _update_values -> :ok end
      )

      parked_car_id = "68004555-1a0d-4447-99ee-c5c6835086b1"
      check_in_date = DateTime.add(DateTime.utc_now(), -3601)

      hour_value = 10

      result = ParkedCar.checkout(parked_car_id, check_in_date, hour_value: hour_value)

      assert {:ok, price} = result
      assert price >= hour_value
    end
  end
end
