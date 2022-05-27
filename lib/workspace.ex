defmodule Egit.Workspace do
  alias Egit.Error
  alias Egit.Workspace
  @ignore [".", "..", ".git"]

  defstruct pathname: "."

  def new(pathname) do
    %Workspace{pathname: Path.expand(pathname)}
  end

  def list_dir(%Workspace{pathname: pathname}, dirname) do
    path = Path.join(pathname, to_string(dirname))
    entries = File.ls!(path) -- @ignore

    Enum.reduce(entries, %{}, fn name, stats ->
      relative = Path.join(path, name) |> Path.relative_to(pathname)
      Map.put(stats, relative, File.stat!(Path.join(path, name)))
    end)
  end

  def list_files(%Workspace{pathname: pathname} = base, dir \\ nil) do
    dir = if is_nil(dir), do: pathname, else: dir

    if File.dir?(dir) do
      (File.ls!(dir) -- @ignore)
      |> Enum.map(&list_files(base, Path.join(dir, &1)))
      |> List.flatten()
    else
      relative = Path.relative_to(dir, pathname)

      if File.exists?(relative) do
        [relative]
      else
        raise Error.MissingFile, "pathspec '#{relative}' did not match any files"
      end
    end
  end

  def stat_file(%Workspace{pathname: pathname}, path) do
    full_path = Path.join(pathname, path)

    case File.stat(full_path) do
      {:ok, stat} -> stat
      {:error, :enoent} -> raise Error.NoPermission, "stat('#{full_path}')"
      {:error, reason} -> raise Error.UnknownError, "fatal: because of #{reason}"
    end
  end

  def read_file(%Workspace{pathname: pathname}, path) do
    full_path = Path.join(pathname, path)

    case File.read(full_path) do
      {:ok, content} -> content
      {:error, :enoent} -> raise Error.NoPermission, "open('#{full_path}')"
      {:error, reason} -> raise Error.UnknownError, "fatal: because of #{reason}"
    end
  end
end
