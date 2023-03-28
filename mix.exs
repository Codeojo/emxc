defmodule Emxc.MixProject do
  use Mix.Project

  def project do
    [
      app: :emxc,
      version: "0.0.4",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:decimal, "~> 2.0"}
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

  defp docs do
    [
      main: "Emxc.Global.Spot.V3",
      groups_for_docs: [
        API: &(&1[:section] == :api),
        Utilities: &(&1[:section] == :utilities),
        "Market Data (Public)": &(&1[:section] == :market_data),
        "Sub Accounts (Signed)": &(&1[:section] == :sub_accounts),
        "Spot Account/Trade (Signed)": &(&1[:section] == :spot_account_trade),
        "Wallet (Signed)": &(&1[:section] == :wallet)
      ]
    ]
  end
end
