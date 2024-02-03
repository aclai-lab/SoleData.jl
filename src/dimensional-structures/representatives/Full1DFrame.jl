using SoleLogics: intervals_in, short_intervals_in

representatives(fr::Full1DFrame, r::GlobalRel, ::ScalarMetaCondition) = intervals_in(1, X(fr)+1)

representatives(fr::Full1DFrame, r::GlobalRel, ::Union{UnivariateMin,UnivariateMax}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::UnivariateMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::UnivariateMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]

# TODO correct?
# representatives(fr::Full1DFrame, r::GlobalRel, ::Union{UnivariateSoftMax,UnivariateSoftMin}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::UnivariateSoftMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::UnivariateSoftMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]
