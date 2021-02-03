defmodule Egit.Index do
  alias Egit.Index
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

  def load(%Index{lockfile: lockfile} = index) do
    new_index = reset(index)
    file = open_index_file(lockfile)
    if file do
      reader = Checksum.new(file)
      try do
        count = read_header(reader)
        |> IO.inspect(label: "decect the num of entries you have saved last time is")
        # read_entries(reader, count)
        # reader.verify_checksum
      after
        File.close(file)
      end
      new_index
    else
      index
    end
  end

  defp read_header(%Checksum{} = init_checksum) do
    %Checksum{data: data} = Checksum.read(init_checksum, @header_size)

    <<signature::binary-size(4), version::binary-size(4), count::binary-size(4)>> = data
    unless signature == @signature do
      raise Error.Invalid, "Signature: expected '#{@signature}' but found '#{signature}'"
    end

    unless version == i2hex(@version) do
      raise Error.Invalid, "Version: expected '#{@version}' but found '#{hex2i(version)}'"
    end

    hex2i(count)
  end

  defp padding_concat(entry, checksum) do
    if String.last(entry) != "\0" do
      entry = entry<>Checksum.read(checksum, @entry_block)
      padding_concat(entry, checksum)
    else
      entry
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
      Lockfile.commit(lockfile)
    end
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

      {:ok, finish_write(index)}
    else
      {:error, "couldn't acquire the lock of #{lockfile.file_path}" }
    end
  end

  defp reset(%Index{} = index) do
    %{ index | entries: %{},  digest: nil, changed: false }
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
