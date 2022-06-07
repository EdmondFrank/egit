defmodule Egit do
  use Bakeware.Script

  alias Egit.Command
  @moduledoc """
  Documentation for `Egit`.
  Egit is a simple git elixir implementation
  """

  @doc """
  cli main
  """
  @impl Bakeware.Script
  def main([]) do
    IO.puts("Please use egit status/add/init/commit Command")
    0
  end

  def main(args) do
    command = List.first(args)
    Command.execute(command, args)
    0
  end
end
