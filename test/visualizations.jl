using SoleData

@testset "Scalar DNF Visualizations" begin
    
    # Create a test formula with multiple disjuncts and overlapping constraints
    test_formula = @scalarformula(
        ((V1 < 5.85) ∧ (V1 ≥ 5.65) ∧ (V2 < 2.85) ∧ (V3 < 4.55) ∧ (V3 ≥ 4.45)) ∨
        ((V1 < 5.3) ∧ (V2 ≥ 2.85) ∧ (V3 < 5.05) ∧ (V3 ≥ 4.85) ∧ (V4 < 0.35))
    ) |> dnf

  check_same(a, b) = myclean(a) == myclean(b)
  function myclean(s)
    lines = collect(split(s, '\n'))
    join(filter(x->x != "", map(x -> rstrip(x), lines)), "\n")
  end

  @test myclean(
    begin
      io = IOBuffer()
      show_scalardnf(
        io,
        test_formula;
        colwidth=6,
      )
      String(take!(io))
    end) == myclean("
           -Inf  0.35  2.85  4.45  4.55  4.85  5.05  5.30  5.65  5.85  Inf

  V1 :                                                       [====)
  V2 :       [==========)
  V3 :                         [====)

  V1 :       [========================================)
  V2 :                   [==============================================]
  V3 :                                     [====)
  V4 :       [====)
  ")

  @test myclean(
    begin
      io = IOBuffer()
      show_scalardnf(
        io,
        test_formula;
        show_all_variables=true,
        colwidth=6,
      )
      String(take!(io))
    end) == myclean("
           -Inf  0.35  2.85  4.45  4.55  4.85  5.05  5.30  5.65  5.85  Inf

  V1 :                                                       [====)
  V2 :       [==========)
  V3 :                         [====)
  V4 :       [==========================================================]

  V1 :       [========================================)
  V2 :                   [==============================================]
  V3 :                                     [====)
  V4 :       [====)

  ")

end