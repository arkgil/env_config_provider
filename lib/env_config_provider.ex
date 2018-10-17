defmodule EnvConfigProvider do
  @moduledoc """
  [Distillery](https://github.com/bitwalker/distillery) config provider reading configuration data
  from environment variables.

  The information how system environment variables map to application environment variables is
  contained in the schema. Schema is a map, where keys are strings with names of system environment
  variables, and values are "access paths" to application environment variables. Example schema
  looks like this:

      %{
        "PORT" => [:my_app, :http, :port],
        "IP" => [:my_app, :http, :ip],
        "API_KEY" => [:lib, :api_key]
      }

  When the config provider executes, it fetches the values of system environment variables, and
  (if the variables are actually set) puts them in application environment according to given
  access paths. If all of the variables from the schema above were set, executing the provider
  would generate application environment equivalent to following:

      config :my_app, :http,
        port: <value>,
        ip: <value>

      config :lib,
        api_key: <value>

  where `<value>` is the value of system environment variable from the schema. If any of the
  variables was not set, the provider would ignore it. Note that variable values are always strings
  and are never converted to any other type.

  The provider not only places values in application environment, but it deeply merges them with
  existing values. Imagine the application environment like this before running the provider:

      config :my_app, :http,
        port: 12221,
        ip: "127.0.0.1",
        ssl: false

      config :my_app, MyApp.Repo,
        database: "db",
        username: "my_app"

  After running the provider with the schema from previous example, the resulting configuration
  would look like this

      config :my_app, :http,
        port: <value>,
        ip: <value>,
        ssl: false

      config :my_app, MyApp.Repo,
        database: "db",
        username: "my_app"

      config :lib,
        api_key: <value>

  Deep merging is crucial, because other providers might run before this one, and simply setting the
  values (especially under nested keys) could override variables set by these providers.

  ## Installation & usage

  Add this library and Distillery to your dependencies:

      defp deps() do
        [
          {:distillery, "~> 2.0"},
          {:env_config_provider, "~> 0.1"}
        ]
      end

  After that, simply set this module as one of the config providers in your release configuration
  and provide a schema as the only argument:

      set config_providers: [
        {EnvConfigProvider, [MyApp.EnvConfig.schema()]},
        ...
      ]

  ## Access paths

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

  Note that the structure of the access path implies that it needs to contain at least two elements -
  the first one for the application name and the second one for the top-level key. Unfortunately,
  this cannot be reflected in the type specification for `t:app_env_access_path/0` type.
  """

  alias EnvConfigProvider.{Blueprint, SystemEnv, AppEnv}

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

  Learn more from "Access paths" section in the documentation for this module.
  """
  @type app_env_access_path :: [atom(), ...]

  @typedoc """
  Describes the mapping between system and application environment variables.
  """
  @type schema :: %{env_var_name() => app_env_access_path()}

  @typedoc !"""
           The value of application environment variable.
           """
  @type app_env_value() :: term()

  @typedoc !"""
           Mapping between application environment access paths and values which should
           be set under keys these paths lead to.
           """
  @type app_env() :: %{app_env_access_path() => app_env_value()}

  @impl true
  def init([schema]) do
    with {:ok, blueprint} <- Blueprint.from_schema(schema),
         source_env_var_names = Blueprint.get_source_env_var_names(blueprint),
         env_vars = SystemEnv.get(source_env_var_names),
         set_env_vars = Enum.reject(env_vars, fn {_, env_var_value} -> env_var_value == nil end),
         target_app_env_vars =
           set_env_vars
           |> Enum.map(fn {env_var_name, env_var_value} ->
             target_app_env_access_path =
               Blueprint.get_target_app_env_access_path(blueprint, env_var_name)

             {target_app_env_access_path, env_var_value}
           end)
           |> Enum.into(%{}),
         AppEnv.merge_with_existing(target_app_env_vars) do
      :ok
    else
      {:error, err} ->
        raise err
    end
  end

  ## Helpers
end
