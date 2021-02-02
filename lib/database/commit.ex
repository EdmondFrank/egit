defmodule Egit.Commit do
  alias Egit.Commit
  alias Egit.Author
  alias Egit.Tree

  defstruct [
    oid: nil,
    type: "commit",
    parent: nil,
    tree: nil,
    author: %Author{},
    message: ""
  ]

  def new(parent, %Tree{oid: oid}, %Author{} = author, message) do
    %Commit{parent: parent, tree: oid, author: author, message: message}
  end

  def to_s(%Commit{parent: parent, tree: tree, author: author, message: message}) do
    lines = []
    lines = [message | lines]
    lines = ["" | lines]
    lines = ["committer #{Author.to_s(author)}" | lines]
    lines = ["author #{Author.to_s(author)}" | lines]
    lines = if is_nil(parent), do: lines, else: ["parent #{parent}" | lines]
    lines = ["tree #{tree}" | lines]

    Enum.join(lines, "\n")
  end
end
