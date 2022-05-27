defmodule Egit.Command.Status do
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Repository

  def run(_args) do
    repo =
      Path.expand(".")
      |> Path.join(".git")
      |> Repository.new()

    index = Index.load(repo.index)
    untracked = scan_workspace(index, repo.workspace)
    Enum.map(untracked, &IO.puts("?? #{&1}"))
    exit(:normal)
  end

  defp scan_workspace(%Index{} = index, workspace, prefix \\ nil) do
    Workspace.list_dir(workspace, prefix)
    |> Enum.map(fn {path, stat} ->
      if Index.tracked?(index, path) do
        if stat.type == :directory do
          scan_workspace(index, workspace, path)
        end
      else
        if stat.type == :directory, do: path <> "/", else: path
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end
end
