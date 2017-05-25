defmodule ElhexDelivery.Distribution.Deliverator do
  require Logger
  use GenServer
  alias ElhexDelivery.PostalCode.Navigator
  alias ElhexDelivery.Distribution.Deliverator

  @status_options [:standing_by, :loaded, :out_and_about]
  @enforce_keys [:home_postal_code, :status]
  defstruct [:home_postal_code, :status, packages: [], deliveries_count: 0, distance_covered: 0]


  def start_link(postal_code) do
    GenServer.start_link(__MODULE__, postal_code)
  end

  def init(postal_code) do
    deliverator = %Deliverator{
      status: List.first(@status_options),
      home_postal_code: postal_code,
    }

    {:ok, deliverator}
  end

  def state(pid) do
    GenServer.call(pid, {:state})
  end

  def update_status(pid, status) do
    GenServer.call(pid, {:update_status, status})
  end

  def request_delivery(pid, packages) do
    # Only :standing_by status
    GenServer.call(pid, {:request_delivery, packages})
  end

  def deliver(pid) do
    GenServer.cast(pid, {:deliver})
  end

  def permutations([]), do: [[]]
  def permutations(list), do: for postal_code <- list, rest <- permutations(list -- [postal_code]), do: [postal_code | rest]

  def add_home_destination_to_paths(paths, home_postal_code) do
    Enum.map(paths, fn(path) -> [home_postal_code | path] ++ [home_postal_code] end)
  end

  def all_distance_pairs(all_paths), do: all_paths |> Enum.map(&distance_pairs/1)

  def distance_pairs(paths), do: distance_pairs(paths, [])
  def distance_pairs([from, to | tail], acc), do: distance_pairs([to | tail], acc ++ [{from, to}])
  def distance_pairs([_from], acc), do: acc

  def total_distance(path) do
    path
    |> Enum.map(fn({from, to}) ->
      Navigator.get_distance(from, to)
    end)
    |> Enum.reduce(fn(distance, acc) -> distance + acc end)
  end

  def shortest_distance_path(postal_code_list) do
    postal_code_list
    |> permutations()
    |> add_home_destination_to_paths("94062")
    |> Enum.map(fn(paths) ->
      distance = paths |> distance_pairs() |> total_distance()
      distance = distance |> Float.floor(2)
      {paths, distance}
    end)
    |> Enum.sort_by(fn({_paths, distance}) -> distance end, &<=/2)
    |> List.first
  end

  defp shortest_route(packages, home_postal_code) do
    packages
    |> Enum.map(&(&1.postal_code))
    |> Enum.uniq
    |> permutations()
    |> add_home_destination_to_paths(home_postal_code)
    |> all_distance_pairs()
    |> Enum.map(fn(distance_pair_path) ->
      distance = distance_pair_path |> total_distance() |> Float.floor(2)
      {distance_pair_path, distance}
    end)
    |> Enum.sort_by(fn({_paths, distance}) -> distance end, &<=/2)
    |> List.first
  end

  # Callbacks.

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:request_delivery, packages}, _from, deliverator) do
    case deliverator.status do
      :standing_by ->
        message = "#{Enum.count(packages)} packages accepted for delivery"
        deliverator = %Deliverator{deliverator | packages: packages, status: :loaded}
        {:reply, {:ok, message}, deliverator}
      _ ->
        message = ":standing_by status required, current status is #{deliverator.status}"
        {:reply, {:error, message}, deliverator}
    end
  end

  def handle_call({:update_status, status}, _from, deliverator) do
    deliverator = %Deliverator{deliverator | status: status}
    {:reply, deliverator, deliverator}
  end

  def handle_cast({:deliver}, deliverator) do
    deliverator = case deliverator.status do
      :loaded ->
        Logger.info "starting delivery of #{Enum.count(deliverator.packages)} packages"
        {route, total_distance} = shortest_route(deliverator.packages, deliverator.home_postal_code)
        IO.puts "prepared route:"
        IO.inspect route
        IO.puts "total distance is going to be: #{total_distance}"
        IO.puts "starting delivery"
        IO.inspect self()
        GenServer.cast(self(), {:deliver_each, route})
        %Deliverator{deliverator | status: :out_and_about}
      _ ->
        Logger.error ":loaded status is required to start delivery"
        deliverator
    end
    {:noreply, deliverator}
  end

  def handle_cast({:deliver_each, [{from, to} | tail_route]}, deliverator) do
    deliverator = case deliverator.status do
      :out_and_about ->
        # 1. get all packages for the `to` postal code
        distance = Navigator.get_distance(from, to)
        distance_travelled = (deliverator.distance_covered + distance) |> Float.floor(2)
        deliverator = %Deliverator{deliverator | distance_covered: distance_travelled}

        packages_to_be_delivered = Enum.filter(deliverator.packages, fn(package) -> package.postal_code == to end)
        remaining_packages = deliverator.packages -- packages_to_be_delivered
        deliverator = %Deliverator{deliverator | packages: remaining_packages}

        number_of_deliveries = deliverator.deliveries_count + Enum.count(packages_to_be_delivered)

        deliverator = %Deliverator{deliverator | deliveries_count: number_of_deliveries}

        IO.puts "deliverator #{inspect self()} delivered #{Enum.count(packages_to_be_delivered)} package(s) to postal code: #{to}"

        :timer.sleep(1000)
        GenServer.cast(self(), {:deliver_each, tail_route})
        deliverator
      _ ->
        Logger.error ":out_and_about status is required to deliver a package"
        deliverator
    end
    {:noreply, deliverator}
  end

  def handle_cast({:deliver_each, []}, deliverator) do
    deliverator = case deliverator.status do
      :out_and_about ->
        Logger.info "deliveries finished, returning to :standing_by status"
        %Deliverator{deliverator | status: :standing_by}
      _ ->
        Logger.error ":out_and_about status is required to deliver a package"
        deliverator
    end
    {:noreply, deliverator}
  end
end
