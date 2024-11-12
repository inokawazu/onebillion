My shot at the 1 billion row challenge.

**Time** 10:42.64 total 

# How to run

- first generate one billion data rows.

`julia --projectl weatherstat.jl 1000000000 >weatherstat.jl`

- run summarizing script

`julia --projectl summarizeweather.jl`
