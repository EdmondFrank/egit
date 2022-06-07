defmodule Egit.MixProject do
  use Mix.Project

  @app :egit

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      make_targets: ["all"],
      make_clean: ["clean"],
      releases: [{@app, release()}],
      preferred_cli_env: [espec: :test],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Egit, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:deep_merge, "~> 1.0"},
      {:espec, "~> 1.8.3", only: :test},
      {:secure_random, "~> 0.5"},
      {:sorted_set_nif, "~> 1.2"},
      {:bakeware, "~> 0.2.4", runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      steps: [:assemble, &Bakeware.assemble/1],
      strip_beams: Mix.env() == :prod
    ]
  end
end
