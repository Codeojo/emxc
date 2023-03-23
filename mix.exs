defmodule Emxc.MixProject do
  use Mix.Project

  def project do
    [
      app: :emxc,
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:jason, ">= 1.0.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["mrneel"],
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/codeojo/emxc",
        "TradeStudio (Sponsor)" => "https://tradestudio.io"
      },
      files: ~w(lib mix.exs README.md LICENSE),
      description: "a Tesla REST client for the MEXC Exchange"
    ]
  end
end
