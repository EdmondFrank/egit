defmodule Egit do

  alias Egit.Refs
  alias Egit.Blob
  alias Egit.Tree
  alias Egit.Entry
  alias Egit.Commit
  alias Egit.Author
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Database
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
        root_path = Path.expand(".")
        git_path = root_path |> Path.join(".git")
        db_path = git_path |> Path.join("objects")

        workspace = Workspace.new(root_path)
        database = Database.new(db_path)
        refs = Refs.new(git_path)

        entries = Workspace.list_files(workspace)
        |> Enum.map(fn path ->
          data = Workspace.read_file(workspace, path)
          blob = Blob.new(data)

          blob = Database.store(database, blob)

          stat = Workspace.stat_file(workspace, path)
          Entry.new(path, blob.oid, stat)
        end)

        root = Tree.build(entries)
        root = Tree.traverse(root, fn tree -> Database.store(database, tree) end)

        IO.puts "tree: #{root.oid}"

        parent = Refs.read_head(refs)
        name = System.get_env("GIT_AUTHOR_NAME", "Edmondfrank")
        email = System.get_env("GIT_AUTHOR_NAME", "edmomdfrank@yahoo.com")

        author = Author.new(name, email, DateTime.utc_now)
        message = IO.read(:stdio, :line)

        commit = Commit.new(parent, root, author, message)
        commit = Database.store(database, commit)

        Refs.update_head(refs, commit.oid)

        is_root = if is_nil(parent), do: "(root-commit) ", else: ""

        IO.puts "[#{is_root}#{ commit.oid}] #{message}"
        exit(:normal)

      "add" ->
        root_path = Path.expand(".")
        git_path = root_path |> Path.join(".git")

        workspace = Workspace.new(root_path)
        database = Database.new(Path.join(git_path, "objects"))
        index = Index.new(Path.join(git_path, "index"))

        # path = Enum.at(args, 1) |> to_string
        index  = Enum.slice(args, 1..-1)
        |> Enum.reduce(index, fn path, index ->
          Enum.reduce(Workspace.list_files(workspace, path), index, fn sub_path, sub_index ->
            data = Workspace.read_file(workspace, sub_path)
            stat = Workspace.stat_file(workspace, sub_path)

            blob = Blob.new(data)
            blob = Database.store(database, blob)
            Index.add(sub_index, sub_path, blob, stat)
          end)
        end)

        Index.write_updates(index)

        exit(:normal)
      _ ->
        IO.puts(:stderr, "egit: '#{command}' is not a valid command")
        exit({:shutdown, -1})
    end
  end
end
