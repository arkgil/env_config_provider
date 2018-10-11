defmodule EnvConfigProvider.SystemEnvTest do
  use ExUnit.Case, async: false

  import EnvConfigProvider.TestHelpers

  alias EnvConfigProvider.SystemEnv

  describe "get/1" do
    test "returns map with values of requested environment variables" do
      with_env %{"ENV_VAR_1" => "value1", "ENV_VAR_2" => "value2"}, fn ->
        env_vars = SystemEnv.get(["ENV_VAR_1", "ENV_VAR_2"])

        assert "value1" == env_vars["ENV_VAR_1"]
        assert "value2" == env_vars["ENV_VAR_2"]
      end
    end

    test "returns nil as value if environment variable is not set" do
      with_env %{"ENV_VAR_1" => "value1"}, fn ->
        env_vars = SystemEnv.get(["ENV_VAR_1", "ENV_VAR_2"])

        assert "value1" == env_vars["ENV_VAR_1"]
        assert nil == env_vars["ENV_VAR_2"]
      end
    end
  end
end
