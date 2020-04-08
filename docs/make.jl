using Documenter

@info "Loading Petri"
using Petri

@info "Building Documenter.jl docs"
makedocs(
  modules   = [Petri],
  format    = Documenter.HTML(),
  sitename  = "Petri.jl",
  doctest   = false,
  checkdocs = :none,
  pages     = Any[
    "Petri.jl" => "index.md",
    "Basic Usage" => "usage.md",
    "Library Reference" => "api.md",
  ]
)

@info "Deploying docs"
deploydocs(
  target = "build",
  repo   = "github.com/mehalter/Petri.jl.git",
  branch = "gh-pages"
)
