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
end
