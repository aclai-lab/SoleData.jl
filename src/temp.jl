using SoleData
using DataFrames
import SoleData: PropositionalLogiset
import SoleBase: ScalarCondition

df = DataFrame([1 2 3 4; 5 6 7 8], :auto)
# α1 = Atom(ScalarCondition())