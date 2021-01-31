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
end
