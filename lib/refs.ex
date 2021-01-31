defmodule Egit.Refs do
  alias Egit.Refs
  alias Egit.Lockfile
  alias Egit.Error
  defstruct [pathname: "."]

  def new(pathname) do
    %Refs{pathname: pathname}
  end

  def update_head(%Refs{pathname: pathname}, oid) do

    lockfile = Lockfile.new(head_path(pathname))
    lockfile = Lockfile.hold_for_update(lockfile)

    unless lockfile.lock do
      raise Error.LockDenied, "Could not acquire lock on file: #{head_path(pathname)}"
    end

    Lockfile.write(lockfile, oid)
    Lockfile.write(lockfile, "\n")
    Lockfile.commit(lockfile)
  end

  def read_head(%Refs{pathname: pathname}) do
    head = head_path(pathname)
    if File.exists?(head) do
      File.read!(head)
    end
  end

  defp head_path(pathname) do
    Path.join(pathname, "HEAD")
  end
end
