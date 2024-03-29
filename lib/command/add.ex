defmodule Egit.Command.Add do
  alias Egit.Blob
  alias Egit.Index
  alias Egit.Error
  alias Egit.Database
  alias Egit.Workspace
  alias Egit.Repository

  def run(args) do
    repo = Path.expand(".")
    |> Path.join(".git")
    |> Repository.new

    {:ok, index} = Index.load_for_update(repo.index)

    try do
      Enum.slice(args, 1..-1)
      |> Enum.reduce(index, &add_to_index(repo, &1, &2))
      |> Index.write_updates

    rescue
      e in Error.MissingFile ->
        IO.puts(:stderr, "fatal: #{e.message}")
      Index.release_lock(index)
      exit({:shutdown, 128})
      e in Error.NoPermission ->
        IO.puts(:stderr, "fatal: #{e.message}")
      Index.release_lock(index)
      exit({:shutdown, 128})
    end

    exit(:normal)
  end

  defp expanded_paths(repo, path) do
    Workspace.list_files(repo.workspace, path)
  end

  defp add_to_index(repo, path, index) do
    Enum.reduce(
      expanded_paths(repo, path),
      index,
      fn sub_path, sub_index ->
        data = Workspace.read_file(repo.workspace, sub_path)
        stat = Workspace.stat_file(repo.workspace, sub_path)

        blob = Blob.new(data)
        blob = Database.store(repo.database, blob)
        Index.add(sub_index, sub_path, blob, stat)
    end)
  end
end
