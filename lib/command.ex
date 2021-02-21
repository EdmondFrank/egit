defmodule Egit.Command do
  alias Egit.Command.Init
  alias Egit.Command.Add
  alias Egit.Command.Commit

  @commands %{
    "init" => Init,
    "add" => Add,
    "commit" => Commit
  }

  def execute(name, args) do
    if name in Map.keys(@commands) do
      @commands[name].run(args)
    else
      IO.puts(:stderr, "egit: '#{name}' is not a valid command")
      exit({:shutdown, -1})
    end
  end
end
