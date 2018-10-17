defmodule EnvConfigProvider.AppEnvTest do
  use ExUnit.Case, async: false

  import EnvConfigProvider.TestHelpers

  alias EnvConfigProvider.AppEnv

  describe "merge_with_existing/1" do
    test "sets non-nested variable" do
      with_app_env :app, [], fn ->
        AppEnv.merge_with_existing(%{[:app, :key] => "value"})

        assert "value" == Application.get_env(:app, :key)
      end
    end

    test "overrides non-nested variable" do
      with_app_env :app, [key: :value], fn ->
        AppEnv.merge_with_existing(%{[:app, :key] => "value"})

        assert "value" == Application.get_env(:app, :key)
      end
    end

    test "sets nested variable" do
      with_app_env :app,
                   [
                     nested: [
                       one: :value
                     ]
                   ],
                   fn ->
                     AppEnv.merge_with_existing(%{
                       [:app, :nested, :two] => "value",
                       [:app, :other_nested, :one] => "value"
                     })

                     assert :value == Application.get_env(:app, :nested)[:one]
                     assert "value" == Application.get_env(:app, :nested)[:two]
                     assert "value" == Application.get_env(:app, :other_nested)[:one]
                   end
    end

    test "overrides nested variable" do
      with_app_env :app,
                   [
                     nested: [
                       one: :value,
                       two: :value
                     ]
                   ],
                   fn ->
                     AppEnv.merge_with_existing(%{[:app, :nested, :two] => "value"})

                     assert :value == Application.get_env(:app, :nested)[:one]
                     assert "value" == Application.get_env(:app, :nested)[:two]
                   end
    end

    test "sets variable nested more deeply than existing variable" do
      with_app_env :app, [nested: :value], fn ->
        AppEnv.merge_with_existing(%{[:app, :nested, :one] => "value"})

        assert "value" == Application.get_env(:app, :nested)[:one]
      end
    end

    test "sets the variable with longer access path if one access path is a prefix of the other" do
      with_app_env :app, [], fn ->
        AppEnv.merge_with_existing(%{
          [:app, :nested, :key] => "value1",
          [:app, :nested, :key, :deeper] => "value2"
        })

        assert "value2" == Application.get_env(:app, :nested)[:key][:deeper]
      end
    end
  end
end
