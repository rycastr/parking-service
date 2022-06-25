ExUnit.start()

Mox.defmock(Ports.MockParkedCarRepository, for: Ports.ParkedCarRepository)
Application.put_env(:parking, :parked_car_repository, Ports.MockParkedCarRepository)
