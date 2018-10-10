defmodule EnvConfigProvider.Error do
  @moduledoc !"""
             Exception struct returned by various functions on failure.
             """

  defexception [:message]

  ## API

  @doc !"""
       Returns new error struct with given message.
       """
  @spec new(String.t()) :: Exception.t()
  def new(message) when is_binary(message) do
    %__MODULE__{message: message}
  end
end
