defmodule Egit.Index.Entry do
  @regular_mode     0o100644
  @executable_mode  0o100755
  @max_path_size    0xfff
  @entry_block      8

  alias Egit.Index.Entry
  defstruct [
    ctime: nil, ctime_nsec: nil,
    mtime: nil, mtime_nsec: nil,
    dev: nil, ino: nil, mode: nil, uid: nil, gid: nil, size: nil,
    oid: nil, flags: nil, path: nil
  ]

  def create(pathname, oid, stat) do
    path = to_string(pathname)
    mode = get_mode(stat)
    flags = Enum.min([byte_size(path), @max_path_size])

    %Entry{
      ctime: unix_time(stat.ctime), ctime_nsec: nsec(stat.ctime),
      mtime: unix_time(stat.mtime), mtime_nsec: nsec(stat.mtime),
      dev: stat.major_device, ino: stat.inode, mode: mode,
      uid: stat.uid, gid: stat.gid, size: stat.size,
      oid: oid, flags: flags, path: path
    }
  end

  def parse(binary_string) do
    <<ctime::binary-size(4), ctime_nsec::binary-size(4),
      ctime::binary-size(4), mtime_nsec::binary-size(4),
      dev::binary-size(4), ino::binary-size(4), mode::binary-size(4),
      uid::binary-size(4), gid::binary-size(4), size::binary-size(4),
      oid::binary-size(20), flags::binary-size(2), path::binary>> =  binary_string
  end

  def to_s(%Entry{} = e) do
    string = "#{i2hex(e.ctime)}#{i2hex(e.ctime_nsec)}"
    string = string <> "#{i2hex(e.mtime)}#{i2hex(e.mtime_nsec)}"
    string = string <> "#{i2hex(e.dev)}#{i2hex(e.ino)}#{i2hex(e.mode)}"
    string = string <> "#{i2hex(e.uid)}#{i2hex(e.gid)}#{i2hex(e.size)}"
    string = string <> "#{pack_oid(e.oid)}#{i2hex(e.flags, 4)}#{pack_oid(Base.encode16(e.path))}\0"

    padding = byte_size(string) |> rem(@entry_block)
    pad = if padding > 0, do: Enum.map(1..@entry_block - padding, fn _ -> "\0" end) |> Enum.join(), else: ""
    string <> pad
  end

  defp pack_oid(oid) do
    oid |> String.upcase |> Base.decode16!
  end

  defp i2hex(int, bytes \\ @entry_block) do
    Integer.to_string(int, 16)
    |> String.pad_leading(bytes, "0")
    |> Base.decode16!
  end

  defp convert_naive_time(time) do
    time
    |> NaiveDateTime.from_erl!
    |> DateTime.from_naive!("Etc/UTC")
  end

  defp unix_time(time) do
    time |> convert_naive_time |> DateTime.to_unix
  end

  defp nsec(time) do
    {_, mirco_sec} = time |> convert_naive_time |> DateTime.to_gregorian_seconds
    mirco_sec
  end

  defp get_mode(%{mode: mode}) do
    has_executable_flags = mode
    |> Integer.to_string(@entry_block)
    |> String.to_integer(@entry_block)
    |> Bitwise.&&&(73) > 0
    if has_executable_flags do
      @executable_mode
    else
      @regular_mode
    end
  end
end
