defmodule EgitTest do
  use ExUnit.Case
  doctest Egit

  test "greets the world" do
    assert Egit.hello() == :world
  end
end
