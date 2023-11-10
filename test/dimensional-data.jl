_ninstances = 4
for ((channel_size1, channel_size2), shouldfail) in [
    ((),()) => false,
    ((1),(1)) => false,
    ((1,2),(1,2)) => false,
    ((1,2),(1,)) => true,
    ((1,),()) => true,
    ((1,2),()) => true,
]
    df = DataFrame(
        x=[rand(channel_size1...) for i_instance in 1:_ninstances],
        y=[rand(channel_size2...) for i_instance in 1:_ninstances]
    )

    if shouldfail
        @test_throws AssertionError SoleData.dataframe2cube(df)
    else
        cube, varnames = @test_nowarn SoleData.dataframe2cube(df)
    end
end
