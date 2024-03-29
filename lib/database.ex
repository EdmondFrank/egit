defmodule Egit.Database do
  alias Egit.Blob
  alias Egit.Tree
  alias Egit.Commit
  alias Egit.Index
  alias Egit.Database
  defstruct pathname: "."

  def new(pathname) do
    %Database{ pathname: Path.expand(pathname) }
  end

  def store(%Database{pathname: pathname}, object) do
    string = to_s(object)
    content = "#{object.type} #{byte_size(string)}\0#{string}"
    oid = :crypto.hash(:sha, content) |> Base.encode16(case: :lower)
    object = %{ object | oid: oid }
    write_object(pathname, object.oid, content)
    object
  end

  defp to_s(%Blob{} = obj), do: Blob.to_s(obj)
  defp to_s(%Tree{} = obj), do: Tree.to_s(obj)
  defp to_s(%Commit{} = obj), do: Commit.to_s(obj)
  defp to_s(%Index.Entry{} = obj), do: Index.Entry.to_s(obj)

  defp write_object(pathname, oid, content) do
    object_path = pathname
    |> Path.join(String.slice(oid, 0..1))
    |> Path.join(String.slice(oid, 2..-1))

    dirname = Path.dirname(object_path)
    temp_path = Path.join(dirname, generate_temp_name())

    unless File.exists?(object_path) do
      flags = [:read, :write]
      unless File.exists?(dirname) do
        File.mkdir_p(dirname)
      end
      {:ok, file} = File.open(temp_path, flags)
      compressed = :zlib.compress(content)
      IO.binwrite(file, compressed)
      File.close(file)
      File.rename(temp_path, object_path)
    end
  end

  defp generate_temp_name() do
    temp_chat = Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9) ++ Enum.to_list(?A..?Z)
    "tmp_obj_#{Enum.take_random(temp_chat, 12)}"
  end
end
