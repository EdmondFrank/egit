defmodule Egit.Error do
  defmodule LockDenied do
    defexception message: "could not acquire lock on file"
  end

  defmodule MissingParent do
    defexception message: "missing parent"
  end

  defmodule NoPermission do
    defexception message: "no permission"
  end

  defmodule UnknownError do
    defexception message: "unknown errors occured"
  end

  defmodule EndOfFile do
    defexception message: "unexpected end-of-file while reading file"
  end

  defmodule MissingFile do
    defexception message: "no such file"
  end

  defmodule Invalid do
    defexception message: "gave an invalid result"
  end
end
