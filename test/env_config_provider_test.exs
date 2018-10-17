defmodule EnvConfigProviderTest do
  use ExUnit.Case, async: false

  import EnvConfigProvider.TestHelpers

  test "sets the value of given environment variable in application environment" do
    schema = %{"ENV_VAR" => [:app, :key]}
    env_var_value = "value1"

    with_app_env :app, [], fn ->
      with_env %{"ENV_VAR" => env_var_value}, fn ->
        EnvConfigProvider.init([schema])

        assert env_var_value == Application.get_env(:app, :key)
      end
    end
  end

  test "sets the values of multiple environment variables in application environment" do
    schema = %{"ENV_VAR_1" => [:app, :key], "ENV_VAR_2" => [:app, :nested, :key]}
    env_var_1_value = "value1"
    env_var_2_value = "value2"

    with_app_env :app, [], fn ->
      with_env %{"ENV_VAR_1" => env_var_1_value, "ENV_VAR_2" => env_var_2_value}, fn ->
        EnvConfigProvider.init([schema])

        assert env_var_1_value == Application.get_env(:app, :key)
        assert env_var_2_value == Application.get_env(:app, :nested)[:key]
      end
    end
  end

  test "doesn't set the value of environment variable if it is not set" do
    schema = %{"ENV_VAR" => [:app, :key]}

    EnvConfigProvider.init([schema])

    assert nil == Application.get_env(:app, :key)
  end

  test "deep merges the value of environment variable with application environment, overriding it" do
    schema = %{
      "ENV_VAR_1" => [:app, :key],
      "ENV_VAR_2" => [:app, :nested, :key],
      "ENV_VAR_3" => [:app, :other_nested, :key]
    }

    env_var_1_value = "value1"
    env_var_2_value = "value2"
    env_var_3_value = "value3"

    with_app_env :app,
                 [
                   key: :value,
                   nested: :value,
                   other_nested: [
                     other_key: :value
                   ]
                 ],
                 fn ->
                   with_env %{
                              "ENV_VAR_1" => env_var_1_value,
                              "ENV_VAR_2" => env_var_2_value,
                              "ENV_VAR_3" => env_var_3_value
                            },
                            fn ->
                              EnvConfigProvider.init([schema])

                              assert env_var_1_value == Application.get_env(:app, :key)
                              assert env_var_2_value == Application.get_env(:app, :nested)[:key]

                              assert env_var_3_value ==
                                       Application.get_env(:app, :other_nested)[:key]

                              # existing key was left intact
                              assert :value ==
                                       Application.get_env(:app, :other_nested)[:other_key]
                            end
                 end
  end

  test "doesn't override application environment if the environment variable is not set" do
    schema = %{
      "ENV_VAR_1" => [:app, :key],
      "ENV_VAR_2" => [:app, :nested, :key],
      "ENV_VAR_3" => [:app, :nested, :other_key]
    }

    with_app_env :app,
                 [
                   key: :value,
                   nested: [
                     key: :value,
                     other_key: :value
                   ]
                 ],
                 fn ->
                   EnvConfigProvider.init([schema])

                   assert :value == Application.get_env(:app, :key)
                   assert :value == Application.get_env(:app, :nested)[:key]
                   assert :value == Application.get_env(:app, :nested)[:other_key]

                   # first-level key does not hold any value because there was no nested key to set
                   assert nil == Application.get_env(:app, :other_nested)
                 end
  end

  test "raises an exception when schema is invalid" do
    invalid_schema = %{"ENV_VAR" => [:app, "key"]}

    assert_raise EnvConfigProvider.Error, fn ->
      EnvConfigProvider.init([invalid_schema])
    end
  end
end
