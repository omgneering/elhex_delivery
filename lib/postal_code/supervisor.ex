defmodule ElhexDelivery.PostalCode.Supervisor do
  use Supervisor
  alias ElhexDelivery.PostalCode.{Store, Navigator}

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Store, []),
      worker(Navigator, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
