defmodule Egit.Entry do

  @moduledoc """
  An Entry is a simple structure that exists to package up the information that Tree needs to know about its contents:
  1. the object ID
  2. filename
  3. mode of each file
  """
  @regular_mode         "100644"
  @executable_mode      "100755"
  @directory_mode       "40000"

  alias Egit.Entry

  defstruct [name: nil, oid: nil, mode: nil]

  def new(name, oid, stat) do
    %Entry{name: name, oid: oid, mode: get_mode(stat)}
  end
  defp get_mode(%{mode: mode}) do
    # 001 000 111 101 101(o)
    # 000 000 001 001 001(o)
    #                    &&&
    #                  >= 1?
    # 111(o) => 73(d)
    has_executable_flags = mode
    |> Integer.to_string(8)
    |> String.to_integer(8)
    |> Bitwise.&&&(73) > 0
    if has_executable_flags do
      @executable_mode
    else
      @regular_mode
    end
  end

  def to_s(%Entry{mode: mode, name: name, oid: oid}) do
    "#{mode} #{name}\0#{oid |> String.upcase |> Base.decode16!}"
  end


  def basename(%Entry{name: name}) do
    Path.basename(name)
  end
  def basename(path), do: Path.basename(path)

  def parent_directories(%Entry{name: name}) do
    name
    |> String.split("/", trim: true)
    |> Enum.reduce([], fn path, acc ->
      [Path.join(to_string(List.first(acc)), path) | acc]
    end)
    |> Enum.reverse
    |> Enum.slice(0..-2)
  end

  def tree_mode do
    @directory_mode
  end
end
