defmodule Egit.Command.Commit do
  alias Egit.Refs
  alias Egit.Tree
  alias Egit.Index
  alias Egit.Commit
  alias Egit.Author
  alias Egit.Database
  alias Egit.Repository

  def run(_args) do
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
  end
end
