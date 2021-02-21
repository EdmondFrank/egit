defmodule Egit.Repository do
  alias Egit.Refs
  alias Egit.Index
  alias Egit.Workspace
  alias Egit.Database
  alias Egit.Repository

  defstruct [
    git_path: ".git",
    database: %Database{},
    index: %Index{},
    refs: %Refs{},
    workspace: %Workspace{},
  ]

  def new(git_path) do
    %Repository{
      git_path: git_path,
      refs: Refs.new(git_path),
      index: Index.new(Path.join(git_path, "index")),
      workspace: Workspace.new(Path.dirname(git_path)),
      database: Database.new(Path.join(git_path, "objects"))
    }
  end
end
