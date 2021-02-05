defmodule IndexSpec do
  use ESpec
  alias Egit.Index

  describe Index do

    let :tmp_path, do: Path.expand("../tmp", __DIR__)
    let :index_path, do: Path.join(tmp_path(), "index")
    let :index, do: index_path() |> Index.new

    let :stat, do: File.stat!(__DIR__)
    let :oid, do: SecureRandom.hex(20)

    it "adds a singel file" do
      save_index = Index.add(index(), "alice.txt", %{oid: oid()}, stat())
      expect Map.keys(save_index.entries) |> to(eq ["alice.txt"])
    end
  end
end
