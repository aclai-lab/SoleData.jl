# SoleBase

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/SoleBase.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleBase.jl/dev)
[![Build Status](https://travis-ci.com/aclai-lab/SoleBase.jl.svg?branch=master)](https://travis-ci.com/aclai-lab/SoleBase.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/aclai-lab/SoleBase.jl?svg=true)](https://ci.appveyor.com/project/aclai-lab/SoleBase-jl)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/SoleBase.jl.svg)](https://cirrus-ci.com/github/aclai-lab/SoleBase.jl)
[![Coverage](https://codecov.io/gh/aclai-lab/SoleBase.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/aclai-lab/SoleBase.jl)
[![Coverage](https://coveralls.io/repos/github/aclai-lab/SoleBase.jl/badge.svg?branch=master)](https://coveralls.io/github/aclai-lab/SoleBase.jl?branch=master)


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

