defmodule Egit.Command.Init do
  def run(args) do
    path = Enum.at(args, 1) |> to_string
    root_path = Path.expand(path)
    git_path = root_path |> Path.join(".git")
    Enum.each(["objects", "refs"], fn dir ->
      case git_path |> Path.join(dir) |> File.mkdir_p do
        :ok ->
          IO.puts "Initialize #{dir} directory successfully!"
        {:error, reason} ->
          IO.puts(:stderr, "fatal: #{reason}")
          exit({:shutdown, 1})
        _ ->
          IO.puts(:stderr, "Unknown error occurred")
          exit({:shutdown, -1})
      end
    end)
    IO.puts "Initialized empty egit repository in #{git_path}"
  end
end
