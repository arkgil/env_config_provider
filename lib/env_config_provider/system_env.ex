defmodule EnvConfigProvider.SystemEnv do
  @moduledoc !"""
                        Provides API for retrieving system environment variables.

                        This functionality is in a dedicated module to clearly draw a distinction between pure
                        and non-pure parts of the project. Getting system environment variables is strictly
                        non-pure operation.
             """

  @doc !"""
       Returns a map with names and values of requested environment variables.

       All variables from `env_var_names` list are present as keys in the returned map. A value
       under key is `nil` if the variable is not set.
       """
  @spec get([EnvConfigProvider.env_var_name()]) :: %{
          EnvConfigProvider.env_var_name() => EnvConfigProvider.env_var_value()
        }
  def get(env_var_names) do
    env_var_names
    |> Enum.map(fn env_var_name ->
      {env_var_name, System.get_env(env_var_name)}
    end)
    |> Enum.into(%{})
  end
end
