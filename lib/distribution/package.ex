defmodule ElhexDelivery.Distribution.Package do
  alias ElhexDelivery.PostalCode.Store
  alias ElhexDelivery.Distribution.Package
  @name_options ["Bat", "Ball", "Book", "Broom"]
  @status_options [:received, :out_for_delivery, :delivered]
  @enforce_keys [:id, :name, :postal_code, :status]
  defstruct [:id, :name, :postal_code, :status, :assigned_to]

  def new_random do
    %Package{
      id: generate_id(),
      name: Enum.random(@name_options),
      postal_code: Store.get_sample_postal_code,
      status: List.first(@status_options),
    }
  end

  def new_random(number), do: Stream.repeatedly(&Package.new_random/0) |> Enum.take(number)

  defp generate_id, do: UUID.uuid1(:hex)
end
