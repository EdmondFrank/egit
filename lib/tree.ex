defmodule Egit.Tree do

  alias Egit.Tree
  @mode "100644"

  defstruct [oid: nil, entries: [], type: "tree"]

  def new(entries) do
    %Tree{entries: entries}
  end

  def to_s(%Tree{entries: entries}) do
    # Putting everything together, this generates a string for each entry consisting of the mode 100644 , a space, the filename, a null byte, and then twenty bytes for the object ID

    # hexdump -C tree
    # 00000000  [74 72 65 65] [20] [37 30] 00  [31 30 30 36 34 34] [20] [65 |tree 70.100644 e|
    #               tree      space   70              100644      space
    # 00000010  67 69 74 2e 65 78] 00 [c3 7f b3 82 1b 41 61 eb c6           |git.ex......Aa..|
    #                egit.ex
    # 00000020  fa 0c 94 86 3f bf 7a e6  97 60 17] [31 30 30 36 34          |....?.z..`.10064|
    #                 Blob oid                         100644
    # 00000030  34] [20] [6d 69 78 2e 65 78  73] 00 [04 fe bf 1b c4 34      |4 mix.exs......4|
    #               space        mix.exs
    # 00000040  46 fd 22 cf f8 9e ec b6  c4 76 a3 b6 1b 74]                 |F."......v...t|
    # 0000004e

    entries_packed = Enum.sort_by(entries, &(&1.name))
    |> Enum.map(fn entry ->
      "#{@mode} #{entry.name}\0#{entry.oid |> String.upcase |> Base.decode16!}"
    end)

    Enum.join(entries_packed, "")
  end
end
