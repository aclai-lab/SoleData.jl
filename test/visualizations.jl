using SoleData

@testset "Visualizations" begin
  f = @scalarformula(
    ((V1 < 5.85) ∧ (V1 ≥ 5.65) ∧ (V2 < 2.85) ∧ (V3 < 4.55) ∧ (V3 ≥ 4.45) ∧ (V4 < 0.35)) ∨
    ((V1 < 5.3) ∧ (V2 ≥ 2.85) ∧ (V3 < 5.05) ∧ (V3 ≥ 4.85) ∧ (V4 < 0.35))
  ) |> dnf

  io = IOBuffer()
  show_scalardnf(
    io,
      f;
      show_unbounded=true,
      colwidth=6,
  )

  out = String(take!(io))

  check_same(a, b) = myclean(a) == myclean(b)
  function myclean(a)
    lines = collect(filter(x->x != "", split(out, '\n')))
    join(map(x -> rstrip(x), lines), "\n")
  end

  @test check_same(out, """
           -Inf  0.35  2.85  4.45  4.55  4.85  5.05  5.30  5.65  5.85  Inf

    V1 :                                                       [====)
    V2 :       [==========)
    V3 :                         [====)
    V4 :       [====)

    V1 :       [========================================)
    V2 :                   [==============================================]
    V3 :                                     [====)
    V4 :       [====)


  """)

end