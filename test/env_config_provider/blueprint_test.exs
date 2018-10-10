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
end
