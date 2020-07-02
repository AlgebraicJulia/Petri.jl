import Base.Iterators: flatten
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph, Edge

graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

function edgify(δ, transition, reverse::Bool)
    attr = Attributes()
    return map(collect(keys(δ))) do k
      weight = "$(getindex(δ, k))"
      state = "$k"
      attr = Attributes(:label=>weight, :labelfontsize=>"6")
      return Edge(reverse ? ["T_$transition", "S_$state"] :
                            ["S_$state", "T_$transition"], attr)
    end
end

"""
    Graph(model::Model)

convert a Model into a GraphViz Graph. Transition are green boxes and states are blue circles. Arrows go from the input states to the output states for each transition.
"""
function Graph(model::Model)
    ks = collect(keys(model.Δ))
    statenodes = [Node(string("S_$s"), Attributes(:shape=>"circle", :color=>"dodgerblue2")) for s in model.S]
    transnodes = [Node(string("T_$k"), Attributes(:shape=>"square", :color=>"forestgreen")) for k in ks]

    stmts = vcat(statenodes, transnodes)
    edges = map(ks) do k
      vcat(edgify(first(getindex(model.Δ, k)), k, false),
           edgify(last(getindex(model.Δ, k)), k, true))
    end |> flatten |> collect
    stmts = vcat(stmts, edges)
    g = Graphviz.Graph("G", true, stmts, graph_attrs, node_attrs,edge_attrs)
    return g
end
