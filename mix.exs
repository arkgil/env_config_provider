defmodule EnvConfigProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :env_config_provider,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18.0", only: :docs, runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:deep_merge, "~> 0.2"}
    ]
  end

  defp preferred_cli_env do
    [
      docs: :docs
    ]
  end

  defp elixirc_paths(:test), do: ["lib/", "test/shared/"]
  defp elixirc_paths(_), do: ["lib/"]
end
