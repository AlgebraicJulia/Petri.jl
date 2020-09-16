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
Model(s::S, Δ) where S<:Int = Model(1:s, Δ)

"""
    NullPetri

create a Petri net of no states and no transitions
"""
const NullPetri = Model(Int[], Vector{Tuple{Dict{Int, Number},Dict{Int, Number}}}())

"""
    EmptyPetri(n::Int)

create a Petri net of ``n`` states with no transitions
"""
EmptyPetri(n::Int) = Model(collect(1:n), Vector{Tuple{Dict{Int, Number},Dict{Int, Number}}}())

"""
    EmptyPetri(s::Vector{T})

create a Petri net with states ``s`` with no transitions
"""
EmptyPetri(s::Vector{T}) where T = Model(s, Vector{Tuple{Dict{T, Number},Dict{T, Number}}}())
