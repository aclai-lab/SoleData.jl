using Test
using SoleData

# Tests for VariableDistance

# let's consider a motif, that is, a little representative shapelet
motif_example = [0.1, 0.2, 0.3, 0.4, 0.5]
my_motif = [0.0, 0.0, 0.0, 0.3, 0.4, 0.5]
 
vd = VariableDistance(1, motif_example) # id=1 is totally arbitrary
@test i_variable(vd) == 1
@test reference(vd) == motif_example

@test computeunivariatefeature(vd, reference(vd)) == 0
@test computeunivariatefeature(vd, my_motif) == 0.4

vd_propositional = VariableDistance(1, 36)
@test computeunivariatefeature(vd, 37) == 1.0
