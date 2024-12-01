defmodule Retrieval.Mixfile do
  use Mix.Project

  def project do
    [app: :retrieval,
     version: "1.0.0",
     elixir: "~> 1.17",
     description: "Trie implementation in pure Elixir that supports pattern based lookup and other functionality.",
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 1.4", only: :dev},
     {:ex_doc, "~> 0.35", only: :dev}]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["jimmybot, mdg"],
      links: %{github: "https://github.com/pathpub/retrieval"}
    ]
  end
end
