defmodule EnvConfigProvider do
  @moduledoc """
  [Distillery](https://github.com/bitwalker/distillery) config provider reading configuration data
  from environment variables.
  """

  @behaviour Mix.Releases.Config.Provider

  @typedoc """
  The name of system environment variable, a string.
  """
  @type env_var_name :: String.t()

  @typedoc !"""
           The value of system environment variable, a string or `nil` if variable is not set.
           """
  @type env_var_value :: String.t() | nil

  @typedoc """
  List of atoms describing the access path to application environment variable.

  Application environment API allows to set variables scoped to the application name and one,
  top-level key. However, in Elixir a lot of libraries use nested keyword lists as values in
  application environment. For example, in Ecto we can define the database connection details
  and credentials as follows:

      config :ecto, SomeApp.Repo,
        database: "...",
        username: "...",
        hostname: "...",
        port: ...

  Here the application name is `:ecto` and `SomeApp.Repo` is a top-level key. Other keys are not
  related to application environment API - they are just keys in the keyword list.

  In this case, the list of atoms describing the access to the value under the `:database` key looks
  as follows:

      [:ecto, SomeApp.Repo, :database]

  The first atom in the list is an application name. The second atom is the top-level key. The rest
  of atoms (in this case a single atom) describe the access path to the sequence of nested keyword
  lists. In the example above, `:database` key points to a string and not a keyword list, so it's
  the last key in the path.

  Note that the structure of the access path implies that it needs to contain at least two segments -
  the first one for the application name and the second one for the top-level key. Unfortunately,
  this cannot be reflected in the type specification.
  """
  @type app_env_access_path :: [atom(), ...]

  @typedoc """
  Describes the mapping between system and application environment variables.
  """
  @type schema :: %{env_var_name() => app_env_access_path()}

  @impl true
  def init([schema]) do
    # zamieniamy schemę na coś co zawiera - nazwę zmiennej środowiskowej, jej oryginalną wartość,
    # sekwencję kluczy (później typecastowaną wartość)
  end
end
