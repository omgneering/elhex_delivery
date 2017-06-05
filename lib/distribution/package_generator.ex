defmodule ElhexDelivery.Distribution.PackageGenerator do
  alias ElhexDelivery.Distribution.Package
  alias ElhexDelivery.PostalCode.Store

  @name_options ["Bat", "Ball", "Book", "Broom"]

  def generate_random do
    name = Enum.random(@name_options)
    postal_code = Store.random_postal_code()
    Package.new(name: name, postal_code: postal_code)
  end

  def generate_random(number) do
    Stream.repeatedly(&generate_random/0) |> Enum.take(number)
  end
end
