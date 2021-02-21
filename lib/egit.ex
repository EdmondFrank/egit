defmodule Egit do

  alias Egit.Refs
  alias Egit.Blob
  alias Egit.Tree
  alias Egit.Commit
  alias Egit.Author
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Database
  alias Egit.Repository
  @moduledoc """
  Documentation for `Egit`.
  Egit is a simple git elixir implementation
  """

  @doc """
  cli main
  """
  def main(args) do
    command = List.first(args)
    case command do
      "init" ->
        path = Enum.at(args, 1) |> to_string
        root_path = Path.expand(path)
        git_path = root_path |> Path.join(".git")
        Enum.each(["objects", "refs"], fn dir ->
          case git_path |> Path.join(dir) |> File.mkdir_p do
            :ok ->
              IO.puts "Initialize #{dir} directory successfully!"
            {:error, reason} ->
              IO.puts(:stderr, "fatal: #{reason}")
              exit({:shutdown, 1})
            _ ->
              IO.puts(:stderr, "Unknown error occurred")
              exit({:shutdown, -1})
          end
        end)
        IO.puts "Initialized empty egit repository in #{git_path}"
      "commit" ->

        repo = Path.expand(".")
        |> Path.join(".git")
        |> Repository.new

        index = Index.load(repo.index)

        root = Tree.build(index.entries)
        root = Tree.traverse(root, fn tree -> Database.store(repo.database, tree) end)

        IO.puts "tree: #{root.oid}"

        parent = Refs.read_head(repo.refs)
        name = System.get_env("GIT_AUTHOR_NAME", "Edmondfrank")
        email = System.get_env("GIT_AUTHOR_NAME", "edmomdfrank@yahoo.com")

        author = Author.new(name, email, DateTime.utc_now)
        message = IO.read(:stdio, :line)

        commit = Commit.new(parent, root, author, message)
        commit = Database.store(repo.database, commit)

        Refs.update_head(repo.refs, commit.oid)

        is_root = if is_nil(parent), do: "(root-commit) ", else: ""

        IO.puts "[#{is_root}#{ commit.oid}] #{message}"
        exit(:normal)

      "add" ->
        repo = Path.expand(".")
        |> Path.join(".git")
        |> Repository.new |> IO.inspect(label: "current_repo:")

        {:ok, index} = Index.load_for_update(repo.index)

        try do
          index  = Enum.slice(args, 1..-1)
          |> Enum.reduce(index, fn path, index ->
            Enum.reduce(Workspace.list_files(repo.workspace, path), index, fn sub_path, sub_index ->
              data = Workspace.read_file(repo.workspace, sub_path)
              stat = Workspace.stat_file(repo.workspace, sub_path)

              blob = Blob.new(data)
              blob = Database.store(repo.database, blob)
              Index.add(sub_index, sub_path, blob, stat)
            end)
          end)

          Index.write_updates(index)
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
      _ ->
        IO.puts(:stderr, "egit: '#{command}' is not a valid command")
        exit({:shutdown, -1})
    end
  end
end
