defmodule AgexTest do
  use ExUnit.Case
  doctest Agex

  test "greets the world" do
    assert Agex.hello() == :world
  end
end
