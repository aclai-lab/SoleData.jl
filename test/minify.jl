using Test
using SoleData: minify

A = randn(10000)
minA, b = minify(A)
@test sortperm(minA) == sortperm(A)
@test map(b, minA) == A

A = randn(10,10,10)
minA, b = minify(A)
@test sortperm(vec(minA)) == sortperm(vec(A))
@test map(b, minA) == A

A = randn(10,10,10)
B = randn(10,10,10)
(minA, minB), b = minify([A, B])
@test sortperm(vec(minA)) == sortperm(vec(A))
@test sortperm(vec(minB)) == sortperm(vec(B))
@test map(b, minA) == A
@test map(b, minB) == B

A = Dict([i => r for (i,r) in enumerate(randn(1000))])
B = Dict([i => r for (i,r) in enumerate(randn(1000))])
(minA, minB), b = minify([A, B])
@test sortperm(collect(values(minA))) == sortperm(collect(values(A)))
@test Dict([i => b(r) for (i,r) in minA]) == A
@test sortperm(collect(values(minB))) == sortperm(collect(values(B)))
@test Dict([i => b(r) for (i,r) in minB]) == B
