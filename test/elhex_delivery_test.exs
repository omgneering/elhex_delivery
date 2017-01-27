defmodule ElhexDeliveryTest do
  use ExUnit.Case
  doctest ElhexDelivery

  test "application start" do
    response = Application.start(:elhex_delivery)
    assert response == {:error, {:already_started, :elhex_delivery}}
  end
end
