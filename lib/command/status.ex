defmodule Egit.Command.Status do
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Repository
  alias Discord.SortedSet

  def run(path) do
    repo =
      Path.expand(".")
      |> Path.join(".git")
      |> Repository.new()

    index = Index.load(repo.index)
    untracked = scan_workspace(index, repo.workspace)
    Enum.map(SortedSet.to_list(untracked), &IO.puts("?? #{&1}"))
    exit(:normal)
  end

  def trackable_file?(index, _, path, %File.Stat{type: type}) when type == :regular do
    !Index.tracked?(index, path)
  end

  def trackable_file?(_, _, _, %File.Stat{type: type}) when type != :directory, do: false

  def trackable_file?(index, workspace, path, %File.Stat{}) do
    items = Workspace.list_dir(workspace, path)
    files = Enum.filter(items, fn {_, stat} -> stat.type == :regular end)
    dirs = Enum.filter(items, fn {_, stat} -> stat.type == :directory end)

    Enum.any?([files, dirs], fn list ->
      Enum.any?(list, fn {item_path, item_stat} ->
        trackable_file?(index, workspace, item_path, item_stat)
      end)
    end)
  end

  def trackable_file?(_, _, _, _), do: false

  defp scan_workspace(index, workspace, prefix \\ nil) do
    Workspace.list_dir(workspace, prefix)
    |> Enum.reduce(SortedSet.new(), fn {path, stat}, untracked ->
      if Index.tracked?(index, path) do
        if stat.type == :directory, do: scan_workspace(index, workspace, path), else: untracked
      else
        if trackable_file?(index, workspace, path, stat) do
          SortedSet.add(untracked, if(stat.type == :directory, do: path <> "/", else: path))
        else
          untracked
        end
      end
    end)
  end
end
