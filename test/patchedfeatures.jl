using Test
using SoleData

using DataFrames

f=min

f2 = SoleData.nanpatchedfunction(f, ≥)

X = DataFrame(;
    #  a = [randn(2,3,2), randn(2,3,2), randn(2,3,2), randn(2,3,2), randn(2,3)], # wrong
    myvar=[randn(2, 3), randn(2, 3), randn(2, 3), randn(2, 3), randn(2, 3)], # good
    myvar2=[randn(2, 3), randn(2, 3), randn(5, 3), randn(2, 3), randn(2, 4)], # good but actually bad because channel_size must be uniform
)

a = @test_nowarn SoleData.naturalconditions(X, [f, f2])
b = @test_nowarn SoleData.naturalconditions(X, [f, (>, f2)])
@test length(a) > length(b)

@test_nowarn SoleData.naturalconditions(X, [f, f2]; fixcallablenans=true)
@test_nowarn SoleData.naturalconditions(X, [f]; fixcallablenans=true)
