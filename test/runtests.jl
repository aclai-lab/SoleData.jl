using SoleBase
using DataFrames
using Test

const ts_sin = [sin(i) for i in 1:50000]
const ts_cos = [cos(i) for i in 1:50000]

const df = DataFrame(
    :sex => ["F", "F", "M"],
    :h => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]
)

const df_langs = DataFrame(
    :age => [30, 9],
    :name => ["Python", "Julia"],
    :stat => [deepcopy(ts_sin), deepcopy(ts_cos)]
)

const ages = DataFrame(:age => [35, 38, 37])

@testset "SoleBase.jl" begin

    @testset "dataset" begin
        mfd = MultiFrameDataset([[1],[2]], deepcopy(df))
        original_mfd = deepcopy(mfd)

        @test isa(mfd, MultiFrameDataset)

        @test isa(frame(mfd, 1), SubDataFrame)
        @test isa(frame(mfd, 2), SubDataFrame)

        @test nframes(mfd) == 2

        @test nattributes(mfd) == 2
        @test nattributes(mfd, 1) == 1
        @test nattributes(mfd, 2) == 1

        @test ninstances(mfd) == 3
        @test ninstances(mfd, 1) == 3
        @test ninstances(mfd, 2) == 3

        @test dimension(mfd) == (0, 1)
        @test dimension(mfd, 1) == 0
        @test dimension(mfd, 2) == 1

        # test auto selection of frames
        auto_mfd = MultiFrameDataset(deepcopy(df))
        @test nframes(auto_mfd) == 0
        @test length(spareattributes(auto_mfd)) == nattributes(auto_mfd)

        auto_mfd_all = MultiFrameDataset(deepcopy(df); group = :all)
        @test auto_mfd_all == mfd
        @test !(:mixed in dimension(auto_mfd_all))

        lang_mfd1 = MultiFrameDataset(df_langs; group = :all)
        @test nframes(lang_mfd1) == 2
        @test !(:mixed in dimension(lang_mfd1))

        lang_mfd2 = MultiFrameDataset(df_langs; group = [1])
        @test nframes(lang_mfd2) == 3
        dims_mfd2 = dimension(lang_mfd2)
        @test length(filter(x -> isequal(x, 0), dims_mfd2)) == 2
        @test length(filter(x -> isequal(x, 1), dims_mfd2)) == 1
        @test !(:mixed in dimension(lang_mfd2))

        # addframe!
        @test addframe!(mfd, [1, 2]) == mfd # test return
        @test nframes(mfd) == 3
        @test nattributes(mfd) == 2
        @test nattributes(mfd, 3) == 2

        @test dimension(mfd) == (0, 1, :mixed)
        @test dimension(mfd, 3) == :mixed
        @test dimension(mfd, 3; force = :min) == 0
        @test dimension(mfd, 3; force = :max) == 1

        # removeframe!
        @test removeframe!(mfd, 3) == mfd # test return
        @test nframes(mfd) == 2
        @test nattributes(mfd) == 2
        @test_throws Exception nattributes(mfd, 3) == 2

        # spareattributes
        @test length(spareattributes(mfd)) == 0
        removeframe!(mfd, 2)
        @test length(spareattributes(mfd)) == 1
        addframe!(mfd, [2])
        @test length(spareattributes(mfd)) == 0

        # addinstance!
        new_inst = DataFrame(:sex => ["F"], :h => [deepcopy(ts_cos)])[1,:]
        @test addinstance!(mfd, new_inst) == mfd # test return
        @test ninstances(mfd) == 4
        addinstance!(mfd, ["M", deepcopy(ts_cos)])
        @test ninstances(mfd) == 5

        # removeinstance!
        @test removeinstance!(mfd, ninstances(mfd)) == mfd # test return
        @test ninstances(mfd) == 4
        removeinstance!(mfd, ninstances(mfd))
        @test ninstances(mfd) == 3

        # keeponlyinstances!
        addinstance!(mfd, ["F", deepcopy(ts_cos)])
        addinstance!(mfd, ["F", deepcopy(ts_cos)])
        addinstance!(mfd, ["F", deepcopy(ts_cos)])
        @test keeponlyinstances!(mfd, [1, 2, 3]) == mfd # test return
        @test ninstances(mfd) == 3
        for i in 1:ninstances(mfd)
            @test instance(mfd, i) == instance(original_mfd, i)
        end

        # frame manipulation
        @test addattribute_toframe!(mfd, 1, 2) === mfd # test return
        @test nattributes(mfd, 1) == 2
        @test dimension(mfd, 1) == :mixed

        @test removeattribute_fromframe!(mfd, 1, 2) === mfd # test return
        @test nattributes(mfd, 1) == 1
        @test dimension(mfd, 1) == 0

        # attributes manipulation
        @test newframe!(mfd, deepcopy(ages)) == mfd # test return
        @test nframes(mfd) == 3
        @test nattributes(mfd, 3) == 1

        @test dropframe!(mfd, 3) == DataFrame(deepcopy(ages)) # test return
        @test nframes(mfd) == 2

        newframe!(mfd, deepcopy(ages); existing_attributes = [1])
        @test nframes(mfd) == 3
        @test nattributes(mfd, 3) == 2
        @test dimension(mfd, 3) == 0

        # drop "inner" frame and multiple frames in one operation
        newframe!(mfd, DataFrame(:t2 => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]))
        @test nframes(mfd) == 4
        @test nattributes(mfd) == 4
        @test nattributes(mfd, nframes(mfd)) == 1

        # dropping the frame 3 should result in dropping the first too
        # because the attribute at index 1 is shared between them and will be
        # dropped but frame 1 has just the attribute at index 1 in it, this
        # should result in dropping that frame too
        dropframe!(mfd, 3)
        @test nframes(mfd) == 2
        @test nattributes(mfd) == 2
        @test nattributes(mfd, nframes(mfd)) == 1

        dropframe!(mfd, 2)
        @test nframes(mfd) == 1
        @test nattributes(mfd) == 1

        # RESET
        mfd = deepcopy(original_mfd)

        # dropspareattributes!
        removeframe!(mfd, 2)
        @test dropspareattributes!(mfd) == DataFrame(names(df)[2] => df[:,2])

        # keeponlyattributes!
        mfd_attr_manipulation = MultiFrameDataset([[1], [2], [3, 4]],
            DataFrame(
                :age => [30, 9],
                :name => ["Python", "Julia"],
                :stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)],
                :stat2 => [deepcopy(ts_cos), deepcopy(ts_sin)]
            )
        )
        mfd_attr_manipulation_original = deepcopy(mfd_attr_manipulation)

        @test keeponlyattributes!(mfd_attr_manipulation, [1, 3]) == DataFrame(
                :name => ["Python", "Julia"],
                :stat2 => [deepcopy(ts_cos), deepcopy(ts_sin)]
            ) # test return
        @test mfd_attr_manipulation == MultiFrameDataset([[1], [2]],
            DataFrame(
                :age => [30, 9],
                :stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]
            )
        )
    end
end
