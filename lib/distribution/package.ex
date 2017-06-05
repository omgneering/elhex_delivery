defmodule ElhexDelivery.Distribution.Package do
  alias ElhexDelivery.Distribution.Package

  @enforce_keys [:id, :name, :postal_code]
  defstruct [:id, :name, :postal_code]

  def new(name: name, postal_code: postal_code) do
    %Package{name: name, postal_code: postal_code, id: generate_id()}
  end

  defp generate_id, do: UUID.uuid1(:hex)
end
