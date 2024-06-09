using SoleLogics: intervals_in, short_intervals_in

representatives(fr::Full1DFrame, r::GlobalRel, ::ScalarMetaCondition) = intervals_in(1, X(fr)+1)

representatives(fr::Full1DFrame, r::GlobalRel, ::Union{VariableMin,VariableMax}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::VariableMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::VariableMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]

# TODO correct?
# representatives(fr::Full1DFrame, r::GlobalRel, ::Union{VariableSoftMax,VariableSoftMin}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::VariableSoftMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::VariableSoftMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]
