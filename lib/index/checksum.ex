defmodule Egit.Index.Checksum do
  alias Egit.Index.Checksum
  alias Egit.Error
  @checksum_size 20
  defstruct [file: nil, digest: nil, data: nil]

  def new(file) do
    %Checksum{file: file, digest: :crypto.hash_init(:sha)}
  end

  def read(%Checksum{file: file, digest: digest} = checksum, size) do
    data = IO.read(file, size)
    unless byte_size(data) == size do
      raise Error.EndOfFile, "Unexpected end-of-file while reading index"
    end
    digest = :crypto.hash_update(digest, data)
    %{checksum | digest: digest, data: data}
  end

  def verify_checksum(%Checksum{file: file, digest: digest} = checksum) do
    sum = IO.read(file, @checksum_size)
    unless sum == digest do
      raise Error.InvalidChecksum, "Checksum does not match value stored on disk"
    end
    checksum
  end
end
