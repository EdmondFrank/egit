defmodule Egit.Blob do

  alias Egit.Blob
  defstruct oid: nil, type: "blob", data: nil

  def new(data) do
    %Blob{data: data}
  end

  def to_s(%Blob{data: data}) do
    data
  end
end
