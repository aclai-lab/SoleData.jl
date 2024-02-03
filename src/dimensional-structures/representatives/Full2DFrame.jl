using SoleLogics: intervals2D_in

representatives(fr::Full2DFrame, r::GlobalRel, ::Union{UnivariateMin,UnivariateMax}, ::Union{typeof(minimum),typeof(maximum)}) = intervals2D_in(1,X(fr)+1,1,Y(fr)+1)
representatives(fr::Full2DFrame, r::GlobalRel, ::UnivariateMax, ::typeof(maximum)) = [Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]
representatives(fr::Full2DFrame, r::GlobalRel, ::UnivariateMin, ::typeof(minimum)) = [Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]

# TODO correct?
# representatives(fr::Full2DFrame, r::GlobalRel, ::Union{UnivariateSoftMax,UnivariateSoftMin}, ::Union{typeof(minimum),typeof(maximum)}) = intervals2D_in(1,X(fr)+1,1,Y(fr)+1)
representatives(fr::Full2DFrame, r::GlobalRel, ::UnivariateSoftMax, ::typeof(maximum)) = [Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]
representatives(fr::Full2DFrame, r::GlobalRel, ::UnivariateSoftMin, ::typeof(minimum)) = [Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]

# TODO add bindings for Full2DFrame+IA and Full2DFrame+RCC
