defmodule EnvConfigProvider.AppEnv do
  @moduledoc !"""
                        Implements API for manipulating application environment variables.
             """

  ## API

  @doc !"""
       Merges given application environment variables with current application
       environment.

       Merging is deep, overriding existing variables if necessary and adding any level of nesting
       when required.

       The only tricky bit is when one of the access paths is a prefix of the other, e.g.

           %{[:app, :key] => :value, [:app, :key, :nested] => :nested_value}

       In such cases, the longer access path wins. In the example above, the resulting application
       environment would be equivalent to:

           config :app, :key,
             nested: :nested_value
       """
  @spec merge_with_existing(EnvConfigProvider.app_env()) :: :ok
  def merge_with_existing(target_app_env) do
    # First, group all access paths by the application name and remove it from the access path.
    target_app_env_grouped_by_app =
      Enum.reduce(target_app_env, %{}, fn {[app | access_path], value}, acc ->
        # From this moment all access paths have their first element - the application name -
        # trimmed off.
        Map.update(acc, app, %{access_path => value}, fn env_by_app ->
          Map.put(env_by_app, access_path, value)
        end)
      end)

    target_app_env_grouped_by_app
    # For each application whose environment we want to modify, retrieve its current environment.
    |> Enum.map(fn {app, target_env} ->
      existing_env = Application.get_all_env(app)
      {app, existing_env, target_env}
    end)
    # Merge current environment with existing environment.
    |> Enum.each(fn {app, existing_env, target_env} ->
      target_env
      # Convert target environment to list to make sure that the result of merge is also a list.
      |> Map.to_list()
      # Sort by the length of the access path, so that longer access paths have precedence and
      # override values under their prefixes.
      |> Enum.sort_by(fn {access_path, _} -> length(access_path) end)
      # Expand the access path and the value into nested keyword list.
      |> Enum.map(fn {access_path, value} -> expand_nested_keyword(access_path, value) end)
      # Merge with current application environment.
      |> Enum.reduce(existing_env, fn nested_value, env ->
        DeepMerge.deep_merge(env, nested_value)
      end)
      # Set all keys from new, merged, application environment.
      |> Enum.each(fn {key, value} -> Application.put_env(app, key, value) end)
    end)
  end

  ## Helpers

  @doc !"""
       Takes a list of atoms and a value and expands it into a nested keyword list

       Each atom from the original list except the last one points at the lower-level keyword list.
       Last atom from the list points at the given value.
       """
  @spec expand_nested_keyword(
          EnvConfigProvider.app_env_access_path(),
          EnvConfigProvider.app_env_value()
        ) :: Keyword.t()
  defp expand_nested_keyword([], value) do
    value
  end

  defp expand_nested_keyword([key | other_keys], value) do
    [{key, expand_nested_keyword(other_keys, value)}]
  end
end
