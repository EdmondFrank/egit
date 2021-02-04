defmodule Egit.Index.Checksum do
  alias Egit.Index.Checksum
  alias Egit.Error
  @checksum_size 20
  defstruct [file: nil, digest: nil, data: nil]

  def new(file) do
    %Checksum{file: file, digest: :crypto.hash_init(:sha)}
  end

  def read(%Checksum{file: file, digest: digest} = checksum, size, binary? \\ true) do
    data = if binary?, do: IO.binread(file, size), else: IO.read(file, size)
    case data do
      :eof -> raise Error.EndOfFile, "Unexpected end-of-file while reading index"
      _ ->
        unless byte_size(data) == size do
          raise Error.EndOfFile, "Unexpected end-of-file while reading index"
        end
        digest = :crypto.hash_update(digest, data)
        %{checksum | digest: digest, data: data}
    end
  end

  def verify_checksum(%Checksum{file: file, digest: digest} = checksum) do

    sum = IO.binread(file, @checksum_size)

    unless sum == digest do
      raise Error.Invalid, "Checksum does not match value stored on disk"
    end
    checksum
  end

  def finish(%Checksum{digest: digest} = checksum) do
    final_digest = :crypto.hash_final(digest)
    %{checksum| digest: final_digest}
  end
end
