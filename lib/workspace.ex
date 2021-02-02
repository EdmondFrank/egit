defmodule Egit.Workspace do

  alias Egit.Workspace
  @ignore [".", "..", ".git"]

  defstruct pathname: "."

  def new(pathname) do
    %Workspace{pathname: Path.expand(pathname)}
  end

  def list_files(%Workspace{pathname: pathname} = base, dir \\ nil) do
    dir = if is_nil(dir) , do: pathname, else: dir
    if File.dir?(dir) do
      File.ls!(dir) -- @ignore
      |> Enum.map(&list_files(base, Path.join(dir, &1)))
      |> List.flatten
    else
      [Path.relative_to(dir, pathname)]
    end
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
