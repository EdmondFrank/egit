defmodule Egit.Index do
  alias Egit.Index
  alias Egit.Index.Entry
  alias Egit.Lockfile
  defstruct [lockfile: nil, entries: %{}, digest: nil]

  def new(pathname) do
    %Index{lockfile: Lockfile.new(pathname)}
  end

  def add(%Index{} = index, pathname, %{oid: oid}, stat) do
    entry = Entry.create(pathname, oid, stat)
    %{index | entries: Map.put(index.entries, to_string(pathname), entry)}
  end

  def begin_write(%Index{} = index) do
    %{index | digest: :crypto.hash_init(:sha)}
  end

  def write(%Index{lockfile: lockfile, digest: digest} = index, data) do
    Lockfile.write(lockfile, data, true)
    digest = :crypto.hash_update(digest, data)
    %{index | digest: digest}
  end

  def finish_write(%Index{lockfile: lockfile, digest: digest}) do
    final_digest = :crypto.hash_final(digest)

    Lockfile.write(lockfile, final_digest, true)
    Lockfile.commit(lockfile)
  end

  def write_updates(%Index{lockfile: lockfile, entries: entries} = index) do
    lockfile = Lockfile.hold_for_update(lockfile)
    if lockfile.lock do
      index = %{index | lockfile: lockfile}

      pack = fn num -> String.pad_leading(<<num>>, 4, "\0") end

      index = begin_write(index)

      header = "DIRC#{pack.(2)}#{pack.(length(Map.keys(entries)))}"

      index = write(index, header)
      index = Enum.reduce(entries, index, fn {_key, entry}, index  ->
        write(index, Entry.to_s(entry))
      end)

      {true, finish_write(index)}
    else
      {false, index}
    end
  end
end
