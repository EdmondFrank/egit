defmodule Egit.Index do
  alias Egit.Index
  alias Egit.Tree
  alias Egit.Index.Entry
  alias Egit.Index.Checksum
  alias Egit.Lockfile
  alias Egit.Error

  defstruct [lockfile: nil, entries: %{}, digest: nil, changed: false]

  @header_size      12
  @signature        "DIRC"
  @version          2
  @entry_block      8
  @entry_min_size   64

  def new(pathname) do
    %Index{lockfile: Lockfile.new(pathname)}
  end

  def add(%Index{} = index, pathname, %{oid: oid}, stat) do
    entry = Entry.create(pathname, oid, stat)
    compact_index = discard_conflicts(index, entry)
    %{index | entries: Map.put(compact_index.entries, to_string(pathname), entry), changed: true}
  end

  def discard_conflicts(%Index{} = index, entry) do
    compact_entries = Tree.convert_index_entry_to_entry(entry)
    |> Egit.Entry.parent_directories
    |> Enum.reduce(index.entries, fn dirname, res ->
      Map.delete(res, dirname)
    end)
    %{ index | entries: compact_entries }
  end

  def begin_write(%Index{} = index) do
    %{index | digest: :crypto.hash_init(:sha)}
  end

  def write(%Index{lockfile: lockfile, digest: digest} = index, data) do
    Lockfile.write(lockfile, data, true)
    digest = :crypto.hash_update(digest, data)
    %{index | digest: digest}
  end

  def load(%Index{lockfile: lockfile} = index) do
    file = open_index_file(lockfile)
    if file do
      reader = Checksum.new(file)
      try do
        {:ok, reader, count} = read_header(reader)
        count |> IO.inspect(label: "decect the num of entries you have saved last time is")
        {:ok, save_index, reader} = read_entries(index, reader, count)
        reader |> Checksum.finish |> Checksum.verify_checksum
        save_index
      after
        File.close(file)
      end
    else
      index
    end
  end

  defp read_entries(%Index{entries: entries} = index, %Checksum{} = reader, count) do
    %{entries: load_entries, reader: new_reader} =
      Enum.reduce(1..count, %{entries: entries, reader: reader}, fn _, res ->
        %{reader: reader} = res
        reader = Checksum.read(reader, @entry_min_size)
        %Checksum{data: entry} = reader
        {:ok, entry, reader} = padding_concat(entry, reader)
        entry = Entry.parse(entry)
        %{res | reader: reader, entries: Map.put(res.entries, entry.path, entry)}
      end)

   { :ok, %{index | entries: load_entries}, new_reader }
  end

  defp read_header(%Checksum{} = reader) do
    checksum = Checksum.read(reader, @header_size)
    %Checksum{data: data} = checksum
    <<signature::binary-size(4), version::binary-size(4), count::binary-size(4)>> = data
    unless signature == @signature do
      raise Error.Invalid, "Signature: expected '#{@signature}' but found '#{signature}'"
    end

    unless version == i2hex(@version) do
      raise Error.Invalid, "Version: expected '#{@version}' but found '#{hex2i(version)}'"
    end

    {:ok, checksum, hex2i(count)}
  end

  defp padding_concat(entry, reader) do
    if String.last(entry) != "\0" do
      reader = Checksum.read(reader, @entry_block)
      %{data: data} = reader
      entry = entry<>data
      padding_concat(entry, reader)
    else
      {:ok, entry, reader}
    end
  end

  defp open_index_file(%{file_path: path}) do
    case File.open(path, [:read]) do
      {:ok, file} -> file
      {:error, :enoent} -> nil
      _ -> raise Error.UnknownError
    end
  end



  def finish_write(%Index{lockfile: lockfile, digest: digest}) do
    final_digest = :crypto.hash_final(digest)

    Lockfile.write(lockfile, final_digest, true)
    Lockfile.commit(lockfile)
  end

  def load_for_update(%Index{lockfile: lockfile} = index) do
    lockfile = Lockfile.hold_for_update(lockfile)
    try do
      if lockfile.lock do
        {:ok, load(index)}
      else
        {:error, "couldn't acquire the lock of #{lockfile.file_path}" }
      end
    after
      Lockfile.rollback(lockfile)
    end
  end

  def write_updates(%Index{lockfile: lockfile, entries: entries, changed: changed} = index) do
    if changed do
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

        {:ok, finish_write(index)}
      else
        {:error, "couldn't acquire the lock of #{lockfile.file_path}" }
      end
    else
      Lockfile.rollback(lockfile)
    end
  end

  defp i2hex(int, bytes \\ @entry_block) do
    Integer.to_string(int, 16)
    |> String.pad_leading(bytes, "0")
    |> Base.decode16!
  end

  defp hex2i(binary_hex) do
    binary_hex |> Base.encode16 |> String.trim_leading("0") |> String.to_integer(16)
  end
end
