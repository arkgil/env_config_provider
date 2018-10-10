defmodule EnvConfigProvider.Blueprint do
  @moduledoc !"""
                        Struct describing how system environment variables should be mapped to application
                        environment variables.

                        Note that once created, the blueprint is not modified. It doesn't hold values of
                        neither system nor application environment variables - it only describes how the
                        former maps to the latter.
             """

  alias EnvConfigProvider.Error

  defstruct [:variables]

  @type t :: %__MODULE__{variables: [__MODULE__.Variable.t()]}

  defmodule Variable do
    @moduledoc !"""
               Describes how single system environment variable maps to application environment
               variable.
               """

    defstruct [:source_env_var_name, :target_app_env_access_path]

    @type t :: %__MODULE__{
            source_env_var_name: EnvConfigProvider.env_var_name(),
            target_app_env_access_path: EnvConfigProvider.app_env_access_path()
          }

    ## API

    @spec new(EnvConfigProvider.env_var_name(), EnvConfigProvider.app_env_access_path()) :: t()
    def new(source_env_var_name, target_app_env_access_path) do
      %__MODULE__{
        source_env_var_name: source_env_var_name,
        target_app_env_access_path: target_app_env_access_path
      }
    end
  end

  ## API

  @doc !"""
       Constructs a blueprint given a schema.

       Returns an error when the schema is invalid.
       """
  @spec from_schema(any()) :: {:ok, t()} | {:error, Error.t()}
  def from_schema(schema) do
    case validate_schema(schema) do
      :ok ->
        variables =
          Enum.map(schema, fn {source_env_var_name, target_app_env_access_path} ->
            Variable.new(source_env_var_name, target_app_env_access_path)
          end)

        {:ok, %__MODULE__{variables: variables}}

      {:error, _} = err ->
        err
    end
  end

  ## Helpers

  @spec validate_schema(any()) :: :ok | {:error, Exception.t()}
  defp validate_schema(schema) when is_map(schema) do
    schema |> Enum.to_list() |> validate_schema_mappings()
  end

  defp validate_schema(other) do
    {:error, Error.new("expected schema to be a map but got #{inspect(other)}")}
  end

  @spec validate_schema_mappings([{any(), any()}]) :: :ok | {:error, Exception.t()}
  defp validate_schema_mappings([]) do
    :ok
  end

  defp validate_schema_mappings([mapping | mappings]) do
    case validate_schema_mapping(mapping) do
      :ok ->
        validate_schema_mappings(mappings)

      {:error, _} = err ->
        err
    end
  end

  @spec validate_schema_mapping({any(), any()}) :: :ok | {:error, Exception.t()}
  defp validate_schema_mapping({env_var_name, maybe_app_env_access_path})
       when is_binary(env_var_name) and length(maybe_app_env_access_path) > 1 do
    if Enum.all?(maybe_app_env_access_path, &is_atom/1) do
      :ok
    else
      message =
        "expected all elements of app env access path to be atoms but got" <>
          inspect(maybe_app_env_access_path)

      {:error, Error.new(message)}
    end
  end

  defp validate_schema_mapping({env_var_name, invalid_app_env_access_path})
       when is_binary(env_var_name) do
    message =
      "expected app env access path to be a list with at least two elements but got" <>
        inspect(invalid_app_env_access_path)

    {:error, Error.new(message)}
  end

  defp validate_schema_mapping({invalid_env_var_name, _}) do
    message = "expected env var name to be a string but got #{invalid_env_var_name}"
    {:error, Error.new(message)}
  end
end
