defmodule Egit.Command.Status do
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Repository

  def run(args) do
    repo = Path.expand(".")
    |> Path.join(".git")
    |> Repository.new

    {:ok, index} = Index.load_for_update(repo.index)

    Workspace.list_files(repo.workspace)
    |> Enum.reject(&(Map.has_key?(index.entries, &1)))
    |> Enum.sort
    |> Enum.map(&(IO.puts("?? #{&1}")))

    exit(:normal)
  end
end
