using SoleBase
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

        @test frame(mfd, [1,2]) == [frame(mfd, 1), frame(mfd, 2)]

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

        # test equality between mixed-columns datasets
        mfd1_sim = MultiFrameDataset([[1,2]], DataFrame(:b => [3,4], :a => [1,2]))
        mfd2_sim = MultiFrameDataset([[2,1]], DataFrame(:a => [1,2], :b => [3,4]))
        @test mfd1_sim ≈ mfd2_sim
        @test mfd1_sim == mfd2_sim

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

        # pushinstances!
        new_inst = DataFrame(:sex => ["F"], :h => [deepcopy(ts_cos)])[1,:]
        @test pushinstances!(mfd, new_inst) == mfd # test return
        @test ninstances(mfd) == 4
        pushinstances!(mfd, ["M", deepcopy(ts_cos)])
        @test ninstances(mfd) == 5

        # deleteinstances!
        @test deleteinstances!(mfd, ninstances(mfd)) == mfd # test return
        @test ninstances(mfd) == 4
        deleteinstances!(mfd, ninstances(mfd))
        @test ninstances(mfd) == 3

        # keeponlyinstances!
        pushinstances!(mfd, ["F", deepcopy(ts_cos)])
        pushinstances!(mfd, ["F", deepcopy(ts_cos)])
        pushinstances!(mfd, ["F", deepcopy(ts_cos)])
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
        @test insertframe!(mfd, deepcopy(ages)) == mfd # test return
        @test nframes(mfd) == 3
        @test nattributes(mfd, 3) == 1

        @test dropframe!(mfd, 3) == mfd # test return
        @test nframes(mfd) == 2

        insertframe!(mfd, deepcopy(ages), [1])
        @test nframes(mfd) == 3
        @test nattributes(mfd, 3) == 2
        @test dimension(mfd, 3) == 0

        # drop "inner" frame and multiple frames in one operation
        insertframe!(mfd, DataFrame(:t2 => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]))
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

        @test keeponlyattributes!(mfd_attr_manipulation, [1, 3]) == mfd_attr_manipulation
        @test mfd_attr_manipulation == MultiFrameDataset([[1], [2]],
            DataFrame(
                :age => [30, 9],
                :stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]
            )
        )

        # addressing attributes by name
        mfd1 = MultiFrameDataset([[1],[2]],
            DataFrame(
                :age => [30, 9],
                :name => ["Python", "Julia"],
            )
        )
        mfd_attr_names_original = deepcopy(mfd1)
        mfd2 = deepcopy(mfd1)

        @test hasattributes(mfd1, :age) == true
        @test hasattributes(mfd1, :name) == true
        @test hasattributes(mfd1, :missing_attribute) == false
        @test hasattributes(mfd1, [:age, :name]) == true
        @test hasattributes(mfd1, [:age, :missing_attribute]) == false

        @test hasattributes(mfd1, 1, :age) == true
        @test hasattributes(mfd1, 1, :name) == false
        @test hasattributes(mfd1, 1, [:age, :name]) == false

        @test hasattributes(mfd1, 2, :name) == true
        @test hasattributes(mfd1, 2, [:name]) == true

        @test attributeindex(mfd1, :age) == 1
        @test attributeindex(mfd1, :missing_attribute) == 0
        @test attributeindex(mfd1, 1, :age) == 1
        @test attributeindex(mfd1, 2, :age) == 0
        @test attributeindex(mfd1, 2, :name) == 1

        # addressing attributes by name - insertframe!
        mfd1 = deepcopy(mfd_attr_names_original)
        mfd2 = deepcopy(mfd_attr_names_original)
        @test addframe!(mfd1, [1]) == addframe!(mfd2, [:age])

        # addressing attributes by name - addattribute_toframe!
        mfd1 = deepcopy(mfd_attr_names_original)
        mfd2 = deepcopy(mfd_attr_names_original)
        @test addattribute_toframe!(mfd1, 2, 1) == addattribute_toframe!(mfd2, 2, :age)

        # addressing attributes by name - removeattribute_fromframe!
        @test removeattribute_fromframe!(mfd1, 2, 1) ==
            removeattribute_fromframe!(mfd2, 2, :age)

        # addressing attributes by name - dropattributes!
        mfd1 = deepcopy(mfd_attr_names_original)
        mfd2 = deepcopy(mfd_attr_names_original)
        @test dropattributes!(mfd1, 1) ==
            dropattributes!(mfd2, :age)
        @test mfd1 == mfd2

        # addressing attributes by name - insertframe!
        mfd1 = deepcopy(mfd_attr_names_original)
        mfd2 = deepcopy(mfd_attr_names_original)
        @test insertframe!(
            mfd1,
            DataFrame(:stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]),
            [1]
        ) == insertframe!(
            mfd2,
            DataFrame(:stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]),
            [:age]
        )

        # addressing attributes by name - dropattributes!
        @test dropattributes!(mfd1, [1, 2]) ==
            dropattributes!(mfd2, [:age, :name])
        @test mfd1 == mfd2

        @test nframes(mfd1) == nframes(mfd2) == 1
        @test nattributes(mfd1) == nattributes(mfd2) == 1
        @test nattributes(mfd1, 1) == nattributes(mfd2, 1) == 1

        # addressing attributes by name - keeponlyattributes!
        mfd1 = deepcopy(mfd_attr_names_original)
        mfd2 = deepcopy(mfd_attr_names_original)
        @test keeponlyattributes!(mfd1, [1]) == keeponlyattributes!(mfd2, [:age])
        @test mfd1 == mfd2
    end
end
