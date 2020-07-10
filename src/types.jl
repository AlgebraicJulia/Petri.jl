using AutoHashEquals

"""
    Model{S,D}

Structure for representing the petri net model

represented by states and transition functions
"""
@auto_hash_equals struct Model{S,D}
  S::S  # states
  Δ::D  # transition function
end

Model(s::S, Δ) where S<:UnitRange = Model(collect(s), Δ)

"""
    NullPetri(n::Int)

create a Petri net of ``n`` states with no transitions
"""
const NullPetri = Model(Int[], Vector{Tuple{Dict{Int, Number},Dict{Int, Number}}}())

"""
    NullPetri(n::Int)

create a Petri net of ``n`` states with no transitions
"""
EmptyPetri(n::Int) = Model(collect(1:n), Vector{Tuple{Dict{Int, Number},Dict{Int, Number}}}())
