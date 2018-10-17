defmodule EnvConfigProvider.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :env_config_provider,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: preferred_cli_env(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  def application do
    []
  end

  defp preferred_cli_env do
    [
      docs: :docs,
      dialyzer: :test
    ]
  end

  defp elixirc_paths(:test), do: ["lib/", "test/shared/"]
  defp elixirc_paths(_), do: ["lib/"]

  defp deps do
    [
      {:ex_doc, "~> 0.18.0", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :test, runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:deep_merge, "~> 0.2"}
    ]
  end

  defp docs do
    [
      main: "EnvConfigProvider",
      canonical: "http://hexdocs.pm/env_config_provider",
      source_url: "https://github.com/arkgil/env_config_provider",
      source_ref: "v#{@version}",
      extras: [
        "README.md"
      ]
    ]
  end

  defp description do
    """
    Distillery config provider reading configuration data from environment variables.
    """
  end

  defp package do
    [
      maintainers: ["Arkadiusz Gil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/arkgil/env_config_provider"}
    ]
  end
end
