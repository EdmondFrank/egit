defmodule Egit.Author do

  alias Egit.Author
  defstruct [name: nil, email: nil, time: nil]

  def new(name, email, time) do
    %Author{name: name, email: email, time: time}
  end

  def to_s(%Author{name: name, email: email, time: time}) do
    "#{name} <#{email}> #{DateTime.to_unix(time)} #{Calendar.strftime(time, "%z")}"
  end
end
