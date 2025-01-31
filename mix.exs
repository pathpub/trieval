defmodule Trieval.MixProject do
  use Mix.Project

  def project do
    [
      app: :trieval,
      version: "1.0.0",
      elixir: "~> 1.18",
      description:
        "Trie implementation in pure Elixir that supports pattern based lookup and other functionality.",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/pathpub/trieval"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["jimmybot, mdg", "adamark"],
      links: %{github: "https://github.com/pathpub/trieval"}
    ]
  end
end
