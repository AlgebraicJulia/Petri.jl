using OrdinaryDiffEq
import OrdinaryDiffEq: solve
using GeneralizedGenerated


f1(du, u, p, t) = begin
    du[1] = p[1]*1/u[1]
end
u0 = [1.0]
p = [1.0]
t = (0.0,1.0)
du = similar(u0)
f1(du, u0, p, 0)
@show du
prob = ODEProblem(f1, u0, t, p)
solve(prob, Tsit5())
println("The old fashioned way works")

fex = :((du, u, p, t) -> begin
        du[1] = p[1]*1/u[1]
        end)

f2 = eval(fex)
prob = ODEProblem(f2, u0, t, p)
soln = solve(prob, Tsit5())
println("Works fine with eval")

f3   = mk_function(fex)

f3(du, u0, p, 0)
@show du
println("We can call f3")
f4 = (du, u, p, t) -> f3(du,  u, p, t)
prob = ODEProblem(f4, u0, t, p)
soln = solve(prob, Tsit5())

