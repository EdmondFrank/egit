defmodule Egit.Refs do
  alias Egit.Refs
  defstruct [pathname: "."]

  def new(pathname) do
    %Refs{pathname: pathname}
  end

  def update_head(%Refs{pathname: pathname}, oid) do
    pathname
    |> head_path
    |> File.open([:write], fn file ->
      IO.write(file, oid)
    end)
  end

  def read_head(%Refs{pathname: pathname}) do
    head = head_path(pathname)
    if File.exists?(head) do
      File.read!(head)
    end
  end

  defp head_path(pathname) do
    Path.join(pathname, "HEAD")
  end
end
