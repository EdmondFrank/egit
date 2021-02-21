defmodule Egit do
  alias Egit.Command
  @moduledoc """
  Documentation for `Egit`.
  Egit is a simple git elixir implementation
  """

  @doc """
  cli main
  """
  def main(args) do
    command = List.first(args)
    Command.execute(command, args)
  end
end
