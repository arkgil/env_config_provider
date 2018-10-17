defmodule EnvConfigProvider.TestHelpers do
  @moduledoc """
  Provides various utility functions used in tests
  """

  @type env_vars() :: %{EnvConfigProvider.env_var_name() => EnvConfigProvider.env_var_value()}

  @type app_env_vars() :: %{EnvConfigProvider.app_env_access_path() => term()}

  ## API

  @doc """
  Sets given system environment variables for the execution of the given function.

  Environment variables are cleaned up after the function is done. If the function raises an
  exception, the variables are cleaned up and the exception is reraised.

  This function should be used only in non-asynchronous test cases (i.e. with `sync: false` set).
  """
  @spec with_env(env_vars(), (() -> any())) :: :ok | no_return()
  def with_env(env_vars, fun) when is_map(env_vars) and is_function(fun, 0) do
    System.put_env(env_vars)
    invoke_with_cleanup(fun, fn -> unset_env_vars(env_vars) end)
  end

  @doc """
  Sets given application environment variables for the execution of the given function.

  Environment variables are cleaned up after the function is done. If the function raises an
  exception, the variables are cleaned up and the exception is reraised.

  Environment variables are deep-merged with existing application environment.

  This function should be used only in non-asynchronous test cases (i.e. with `sync: false` set).
  """
  @spec with_app_env(app_env_vars(), (() -> any())) :: :ok | no_return()
  def with_app_env(app_env_vars, fun) when is_map(app_env_vars) and is_function(fun, 0) do
    app_env_vars_before = save_app_env_vars(app_env_vars)
    set_app_env_vars(app_env_vars)
    invoke_with_cleanup(fun, fn -> set_app_env_vars(app_env_vars_before) end)
  end

  ## Helpers

  defp unset_env_vars(env_vars) do
    for env_var_name <- Map.keys(env_vars) do
      System.delete_env(env_var_name)
    end
  end

  defp invoke_with_cleanup(fun, cleanup_fun) do
    fun.()
  rescue
    e ->
      cleanup_fun.()
      reraise(e, System.stacktrace())
  else
    _ ->
      cleanup_fun.()
  end

  defp save_app_env_vars(app_env_vars) do
    app_env_vars
    |> Enum.map(fn {[app, key | key_sequence], _value} ->
      current_value = Application.get_env(app, key)
      {nested_value, access_path} = get_nested_value_and_access_path(current_value, key_sequence)
      {[app, key | access_path], nested_value}
    end)
    |> Enum.uniq_by(&elem(&1, 0))
    |> Enum.into(%{})
  end

  defp set_app_env_vars(app_env_vars) do
    app_env_vars
    |> Enum.each(fn {[app, key | key_sequence], nested_value} ->
      new_value =
        if key_sequence == [] do
          # the value is actually not nested - just set it under the top-level key
          nested_value
        else
          # the value is nested under key sequence and needs to be merged with existing env
          current_value = Application.get_env(app, key, []) || []
          DeepMerge.deep_merge(current_value, nested_kv(key_sequence, nested_value))
        end

      Application.put_env(app, key, new_value)
    end)
  end

  @doc !"""
       Builds a nested keyword list following the given key sequence.

       The value under each key in the sequence, except the last one, is another keyword list. The value
       under the last key is the `value`.

       ## Examples

           iex> nested_kv([:a, :b, :c], 1)
           [a: [b: [c: 1]]]

       """
  defp nested_kv([_ | _] = key_sequence, value) do
    [build_nested_kv(key_sequence, value)]
  end

  defp build_nested_kv([last_key], value) do
    {last_key, value}
  end

  defp build_nested_kv([key | key_sequence], value) do
    {key, [build_nested_kv(key_sequence, value)]}
  end

  @doc !"""
       Walks recursively down the keyword list according to the `key_sequence` until the nested value
       isn't a keyword list.

       Returns the found value and the access path to that value. Note that if the key is not present
       in the keyword list, `nil` is assumed to be the value under that key.
       """
  defp get_nested_value_and_access_path(value, key_sequence, access_path \\ [])

  defp get_nested_value_and_access_path(value, [], access_path) do
    {value, Enum.reverse(access_path)}
  end

  defp get_nested_value_and_access_path(value, [key | key_sequence], access_path) do
    if Keyword.keyword?(value) do
      get_nested_value_and_access_path(Keyword.get(value, key), key_sequence, [key | access_path])
    else
      {value, Enum.reverse(access_path)}
    end
  end
end
