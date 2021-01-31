defmodule Egit do

  alias Egit.Refs
  alias Egit.Blob
  alias Egit.Tree
  alias Egit.Entry
  alias Egit.Commit
  alias Egit.Author
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

          Entry.new(path, blob.oid)
        end)

        tree = Tree.new(entries)
        tree = Database.store(database, tree)
        IO.puts "tree: #{tree.oid}"

        parent = Refs.read_head(refs)
        name = System.get_env("GIT_AUTHOR_NAME", "Edmondfrank")
        email = System.get_env("GIT_AUTHOR_NAME", "edmomdfrank@yahoo.com")

        author = Author.new(name, email, DateTime.utc_now)
        message = IO.read(:stdio, :line)

        commit = Commit.new(parent, tree, author, message)
        commit = Database.store(database, commit)

        Refs.update_head(refs, commit.oid)

        is_root = if is_nil(parent), do: "(root-commit) ", else: ""

        IO.puts "[#{is_root}#{ commit.oid}] #{message}"
        exit(:normal)
      _ ->
        IO.puts(:stderr, "egit: '#{command}' is not a valid command")
        exit({:shutdown, -1})
    end
  end
end
