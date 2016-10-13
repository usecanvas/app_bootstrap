defmodule AppBootstrap.Mixfile do
  use Mix.Project

  def project do
    [app: :app_bootstrap,
     version: "0.1.0",
     elixir: "~> 1.3",
     escript: [main_module: AppBootstrap],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:poison, "~> 2.2.0"},
     {:dialyxir, ">= 0.0.0", only: [:dev]}]
  end
end
