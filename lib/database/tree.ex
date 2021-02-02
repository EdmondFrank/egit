defmodule Egit.Tree do

  alias Egit.Tree
  alias Egit.Entry

  defstruct [oid: nil, entries: %{}, type: "tree", mode: Entry.tree_mode]

  def new do
    %Tree{}
  end

  def add_entry(%Tree{entries: entries} = tree, parents, entry) do
    if length(parents) == 0 do
      %{ tree | entries: Map.put(entries, Entry.basename(entry), entry)}
    else
      [_ | tail] = parents
      sub_tree = Map.get(entries, Entry.basename(List.first(parents)), Tree.new)
      %{ tree | entries: Map.put(entries, Entry.basename(List.first(parents)), Tree.add_entry(sub_tree, tail, entry))}
    end
  end

  def build(entries) do
    root = Tree.new
    Enum.sort_by(entries, &(&1.name))
    |> Enum.reduce(root, fn entry, acc ->
      DeepMerge.deep_merge(acc, Tree.add_entry(acc, Entry.parent_directories(entry), entry))
    end)
  end

  def traverse(%Tree{entries: entries} = tree, block) do
    updated = Enum.map(entries, fn {name, entry} ->
      if is_struct(entry, Tree) do
        %{ name => Tree.traverse(entry, block) }
      end
    end)
    |> Enum.filter(&(not is_nil(&1)))
    |> List.flatten

    new_tree = if length(updated) > 0 do
      Enum.reduce(updated, tree, fn update_entry, acc ->
        put_in(acc.entries, Map.merge(acc.entries, update_entry))
      end)
    else
      tree
    end
    block.(new_tree)
  end

  def to_s(%Tree{entries: entries}) when is_map(entries) do
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
    entries_packed = Enum.map(entries, fn {name, entry} ->
      "#{entry.mode} #{name}\0#{entry.oid |> String.upcase |> Base.decode16!}"
    end)

    Enum.join(entries_packed, "")
  end
end
