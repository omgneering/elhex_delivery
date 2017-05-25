defmodule ElhexDelivery.PostalCode.Store do
  use GenServer
  alias ElhexDelivery.PostalCode.DataParser

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: :postal_code_store)
  end

  def init(_) do
    {:ok, DataParser.parse_data}
  end

  def get_geolocation(postal_code) do
    GenServer.call(:postal_code_store, {:get_geolocation, postal_code})
  end

  def get_sample_postal_code do
    GenServer.call(:postal_code_store, {:get_sample_postal_codes, 1}) |> List.first
  end

  def get_sample_postal_codes(size) do
    GenServer.call(:postal_code_store, {:get_sample_postal_codes, size})
  end

  # Callbacks

  def handle_call({:get_geolocation, postal_code}, _from, geolocation_data) do
    geolocation = Map.get(geolocation_data, postal_code)
    {:reply, geolocation, geolocation_data}
  end

  def handle_call({:get_sample_postal_codes, size}, _from, geolocation_data) do
    postal_codes = geolocation_data |> Map.keys |> Enum.take_random(size)
    {:reply, postal_codes, geolocation_data}
  end
end
