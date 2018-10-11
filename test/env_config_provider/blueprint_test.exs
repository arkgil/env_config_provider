defmodule EnvConfigProvider.BlueprintTest do
  use ExUnit.Case

  alias EnvConfigProvider.{Blueprint, Error}

  describe "from_schema/0" do
    test "returns error when env var name in schema is not a string" do
      invalid_schema = %{nil => [:app, :key]}

      assert {:error, %Error{}} = Blueprint.from_schema(invalid_schema)
    end

    test "returns error when app env access path in schema is not a list" do
      invalid_schema = %{"ENV_VAR" => 1}

      assert {:error, %Error{}} = Blueprint.from_schema(invalid_schema)
    end

    test "returns error when app env access path in schema doesn't have at least two elements" do
      invalid_schema = %{"ENV_VAR" => [:app]}

      assert {:error, %Error{}} = Blueprint.from_schema(invalid_schema)
    end

    test "returns error when app env access path in schema is not composed of only atoms" do
      invalid_schema = %{"ENV_VAR" => [:app, "nested", :key]}

      assert {:error, %Error{}} = Blueprint.from_schema(invalid_schema)
    end

    test "returns error when schema is not a map" do
      invalid_schema = [{"ENV_VAR", [:app, :nested, :key]}]

      assert {:error, %Error{}} = Blueprint.from_schema(invalid_schema)
    end

    test "returns a blueprint struct when schema is valid" do
      schema = %{"ENV_VAR" => [:app, :nested, :key]}

      assert {:ok, %Blueprint{}} = Blueprint.from_schema(schema)
    end
  end

  test "get_source_env_var_names/0 returns a list of names of all source environment variables " <>
         "defined in the blueprint" do
    schema = %{"ENV_VAR_1" => [:app, :key], "ENV_VAR_2" => [:app, :other_key]}
    {:ok, blueprint} = Blueprint.from_schema(schema)

    source_env_var_names = Blueprint.get_source_env_var_names(blueprint)

    assert map_size(schema) == length(source_env_var_names)
    assert "ENV_VAR_1" in source_env_var_names
    assert "ENV_VAR_2" in source_env_var_names
  end
end
