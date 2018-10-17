defmodule EnvConfigProvider.TestHelpers do
  @moduledoc """
  Provides various utility functions used in tests
  """

  @type env_vars() :: %{EnvConfigProvider.env_var_name() => EnvConfigProvider.env_var_value()}
  @type app :: atom()
  @type app_env_vars() :: Keyword.t()

  ## API

  @doc """
  Sets given system environment variables for the execution of the given function.

  Environment variables are cleaned up after the function is done. If the function raises an
  exception, the variables are cleaned up and the exception is reraised.

  This function should be used only in non-asynchronous test cases (i.e. with `async: false` set).
  """
  @spec with_env(env_vars(), (() -> any())) :: :ok | no_return()
  def with_env(env_vars, fun) when is_map(env_vars) and is_function(fun, 0) do
    env_vars_before = System.get_env()
    System.put_env(env_vars)

    invoke_with_cleanup(fun, fn ->
      for env_var_name <- Map.keys(env_vars) do
        System.delete_env(env_var_name)
      end

      System.put_env(env_vars_before)
    end)
  end

  @doc """
  Sets application environment variables for the execution of the given function.

  *All* environment variables belonging to the `app` are cleaned up after the function is done.
  Environment variables belonging to other apps are not saved and restored. This implies that the
  function should only modify application variables belonging to the `app`. If the function raises,
  the variables are cleaned up anyway, and the exception is re-raised.

  This function should be used only in non-asynchronous test cases (i.e. with `async: false` set).
  """
  @spec with_app_env(app, app_env_vars(), (() -> any())) :: :ok | no_return()
  def with_app_env(app, app_env_vars, fun)
      when is_atom(app) and is_list(app_env_vars) and is_function(fun, 0) do
    Enum.each(app_env_vars, fn {key, value} -> Application.put_env(app, key, value) end)

    invoke_with_cleanup(fun, fn ->
      app_env_vars = Application.get_all_env(app)
      Enum.each(app_env_vars, fn {key, _} -> Application.delete_env(app, key) end)
    end)
  end

  ## Helpers

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
end
