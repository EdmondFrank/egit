defmodule Egit.Workspace do

  alias Egit.Workspace
  @ignore [".", "..", ".git"]

  defstruct pathname: "."

  def new(pathname) do
    %Workspace{pathname: Path.expand(pathname)}
  end

  def list_files(%Workspace{pathname: pathname}) do
    {:ok, files} = File.ls(pathname)
    files -- @ignore
  end

  def stat_file(%Workspace{pathname: pathname}, path) do
    {:ok, stat} = File.stat Path.join(pathname, path)
    stat
  end

  def read_file(%Workspace{pathname: pathname}, path) do
    case File.read(Path.join(pathname, path)) do
      {:ok, content} ->
        content
      {:error, reason} ->
        IO.puts(:stderr, "fatal #{reason}")
        exit({:shutdown, -1})
    end
  end
end
