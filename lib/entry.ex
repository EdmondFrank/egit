defmodule Egit.Entry do

  @moduledoc """
  An Entry is a simple structure that exists to package up the information that Tree needs to know about its contents:
  1. the object ID
  2. filename
  3. mode of each file
  """
  @regular_mode "100644"
  @executable_mode "100755"

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
end
