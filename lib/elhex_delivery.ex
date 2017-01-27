defmodule ElhexDelivery do
  use Application

  def start(_type, _args) do
    ElhexDelivery.Supervisor.start_link
  end
end
