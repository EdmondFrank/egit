defmodule Egit.Entry do

  @moduledoc """
  An Entry is a simple structure that exists to package up the information that Tree needs to know about its contents:
  1. the object ID
  2. filename
  3. mode of each file
  """
  alias Egit.Entry

  defstruct [name: nil, oid: nil]

  def new(name, oid) do
    %Entry{name: name, oid: oid}
  end
end
