import Base.Iterators: flatten
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph, Edge

graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

function edgify(δ, transition::Int, reverse::Bool)
    attr = Attributes()
    i = transition
    return map(collect(δ)) do e
      weight = "$(last(e))"
      state = "$(first(e))"
      attr = Attributes(:label=>weight, :labelfontsize=>"6")
      return Edge(reverse ? ["T$i", "$state"] : ["$state", "T$i"], attr)
    end
end

"""
    Graph(model::Model)

convert a Model into a GraphViz Graph. Transition are green boxes and states are blue circles. Arrows go from the input states to the output states for each transition.
"""
function Graph(model::Model)
    statenodes = [Node(string("$s"), Attributes(:shape=>"circle", :color=>"dodgerblue2")) for s in model.S]
    transnodes = [Node("T$i", Attributes(:shape=>"square", :color=>"forestgreen")) for i in 1:length(model.Δ)]

    stmts = vcat(statenodes, transnodes)
    edges = map(enumerate(model.Δ)) do (i,t)
        vcat(edgify(t[1], i, false), edgify(t[2], i, true))
    end |> flatten |> collect
    stmts = vcat(stmts, edges)
    g = Graphviz.Graph("G", true, stmts, graph_attrs, node_attrs,edge_attrs)
    return g
end
