defmodule ElhexDelivery.Distribution.Distributor do
  alias ElhexDelivery.Distribution.{PackageGenerator, Warehouse}

  use GenServer
  require Logger

  # def start_link do
  #   GenServer.start_link(__MODULE__, [])
  # end
  #
  # def init(_) do
  #   schedule_package_sending()
  #   {:ok, []}
  # end
  #
  # def handle_info(:send_packages_to_warehouse, state) do
  #   schedule_package_sending()
  #   do_send_packages_to_warehouse()
  #   {:noreply, state}
  # end
  #
  # defp schedule_package_sending do
  #   Process.send_after(self(), :send_packages_to_warehouse, 1000)
  # end
  #
  # defp do_send_packages_to_warehouse do
  #   IO.puts "Yup"
  # end

  def start_link do
    GenServer.start_link(__MODULE__, %{active: true}, name: __MODULE__)
  end

  def init(state) do
    if state.active do
      schedule_package_sending()
    end

    {:ok, state}
  end

  def activate do
    GenServer.cast(__MODULE__, {:activate})
  end

  def deactivate do
    GenServer.cast(__MODULE__, {:deactivate})
  end

  def handle_cast({:activate}, state) do
    state = Map.put(state, :active, true)
    schedule_package_sending()
    {:noreply, state}
  end

  def handle_cast({:deactivate}, state) do
    state = Map.put(state, :active, false)
    {:noreply, state}
  end

  def handle_info(:send_packages_to_warehouse, state) do
    if state.active do
      schedule_package_sending()
    end
    do_send_packages_to_warehouse()
    {:noreply, state}
  end

  defp schedule_package_sending do
    Process.send_after(self(), :send_packages_to_warehouse, 1000)
  end

  defp do_send_packages_to_warehouse do
    packages = PackageGenerator.generate_random(:rand.uniform(10))
    # Logger.info "sending #{Enum.count(packages)} packages to the warehouse"
    Warehouse.receive_packages(packages)
  end
end
