import Base.Iterators: flatten
using ModelingToolkit
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph, Edge


graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

"""    edgify(root::Operation, transition::Int, reverse::Bool)

convert a Model tranition into a Graphviz edge statement.
if reverse i true assume that this is the outgoing edge.
"""
function edgify(root::Operation, transition::Int, reverse::Bool)
    attr = Attributes()
    i = transition
    if root.op == (+)
        return map(root.args) do x
            weight = ""
            if x.op == (*)
                a = x.args[2].op.name
                weight = "$(x.args[1].value)"
            else
                a = x.op.name
            end
            b = string(a)
            attr =  Attributes(:label=>"$weight", :labelfontsize=>"6")
            return Edge(reverse ? ["T$i", "$b"] : ["$b", "T$i"],attr)
        end
    end
    if root.op == (*)
        b = string(root.args[2].op.name)
        weight = "$(root.args[1].value)"
        attr =  Attributes(:label=>"$weight", :labelfontsize=>"6")
    else
        b = string(root.op.name)
    end
    return [Edge(reverse ? ["T$i", "$b"] : ["$b", "T$i"], attr)]
end

"""    Graph(model::Model)

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
