defmodule Egit.Lockfile do
  alias Egit.Lockfile
  alias Egit.Error
  defstruct [file_path: nil, lock_path: nil, lock: nil]

  def new(path) do
    %Lockfile{file_path: path, lock_path: path <> ".lock"}
  end

  def hold_for_update(%Lockfile{lock: lock, lock_path: lock_path} = lockfile) do
    unless lock do
      flags = [:read, :write, :exclusive]
      case File.open(lock_path, flags) do
        {:ok, file} ->
          %{lockfile | lock: file}
        {:error, :eexist} ->
          %{lockfile | lock: false}
        {:error, :enoent} -> raise Error.MissingParent
        {:error, :eacces} -> raise Error.NoPermission
        _ -> raise Error.UnknownError
      end
    end
  end

  def write(%Lockfile{lock: lock} = lockfile, string, binary? \\ false) do
    raise_on_stale_lock(lockfile)
    if binary?, do: IO.binwrite(lock, string), else: IO.write(lock, string)
  end

  def commit(%Lockfile{lock: lock, lock_path: lock_path, file_path: file_path} = lockfile) do
    raise_on_stale_lock(lockfile)
    File.close(lock)
    File.rename(lock_path, file_path)
    %{lockfile | lock: nil}
  end

  def rollback(%Lockfile{lock: lock, lock_path: lock_path} = lockfile) do
    raise_on_stale_lock(lockfile)
    File.close(lock)
    File.rm(lock_path)
  end

  defp raise_on_stale_lock(%Lockfile{lock: lock, lock_path: lock_path}) do
    unless lock do
      raise "Not holding lock on file: #{lock_path}"
    end
  end
end
