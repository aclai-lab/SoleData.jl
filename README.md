# SoleData

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/SoleData.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleData.jl/dev)
[![Build Status](https://travis-ci.com/aclai-lab/SoleData.jl.svg?branch=main)](https://travis-ci.com/aclai-lab/SoleData.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/aclai-lab/SoleData.jl?svg=true)](https://ci.appveyor.com/project/aclai-lab/SoleData-jl)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/SoleData.jl.svg)](https://cirrus-ci.com/github/aclai-lab/SoleData.jl)
[![Coverage](https://codecov.io/gh/aclai-lab/SoleData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/aclai-lab/SoleData.jl)
[![Coverage](https://coveralls.io/repos/github/aclai-lab/SoleData.jl/badge.svg?branch=main)](https://coveralls.io/github/aclai-lab/SoleData.jl?branch=main)


# PkgTemplates

```julia
t = Template(;
	user="aclai-lab",
	authors=["Eduard I. STAN", "Giovanni PAGLIARINI"],
	plugins=[
		 TravisCI(),
		 Codecov(),
		 Coveralls(),
		 AppVeyor(),
		 GitHubPages(),
		 CirrusCI(),
		 License(; name="MIT"),
	],
)

t("<PACKAGENAME>")
```
then push to the repo
