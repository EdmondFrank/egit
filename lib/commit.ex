defmodule Egit.Commit do
  alias Egit.Commit
  alias Egit.Author
  alias Egit.Tree
  defstruct [oid: nil, type: "commit", tree: nil, author: %Author{}, message: ""]

  def new(%Tree{oid: oid}, %Author{} = author, message) do
    %Commit{tree: oid, author: author, message: message}
  end

  def to_s(%Commit{tree: tree, author: author, message: message}) do
    lines = ["tree #{tree}",
             "author #{Author.to_s(author)}",
             "committer #{Author.to_s(author)}",
             "",
             message
            ]
    Enum.join(lines, "\n")
  end
end
