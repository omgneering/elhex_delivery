defmodule ElhexDelivery.Distribution.Warehouse do
  alias ElhexDelivery.Distribution.Deliverator

  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{
      received_packages: [],
      in_transit_packages: [],
      delivered_packages: [],
      deliverators: []
    }

    {:ok, state}
  end

  def state do
    GenServer.call(__MODULE__, {:state})
  end

  def receive_packages(packages) do
    GenServer.cast(__MODULE__, {:receive_packages, packages})
  end

  def add_deliverator do
    GenServer.cast(__MODULE__, {:add_deliverator})
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:receive_packages, packages}, state) do
    received_packages = state.received_packages ++ packages
    state = Map.put(state, :received_packages, received_packages)
    {:noreply, state}
  end

  def handle_cast({:add_deliverator}, state) do
    {:ok, deliverator_pid} = Deliverator.start_link("94062")
    deliverators = [deliverator_pid | state.deliverators]
    Logger.info "added #{inspect deliverator_pid} deliverator to the warehouse"
    state = Map.put(state, :deliverators, deliverators)
    {:noreply, state}
  end
end
