using CSV, DataFrames, Random, OnlineStats


struct CityStats{T,I}
    mean::T
    std::T
    nsampled::I
end

@inline function update(cs::CityStats, new_data)
    new_nsampled = cs.nsampled + 1

    new_mean = cs.mean
    new_mean += (new_data - cs.mean) / new_nsampled

    new_std = cs.std
    new_std += ((new_data - cs.mean) * (new_data - new_mean) - cs.std)
    new_std /= new_nsampled

    return CityStats(new_mean, new_std, new_nsampled)
end

@inline function newstats(T)
    return CityStats{T,Int}(0, 0, 1)
end

function (@main)(_)
    rows = CSV.Rows("mystats.csv", header=[:city, :temperature], delim=';', types=[String, Float64])

    records = Dict{String,CityStats{Float64,Int}}()

    rowi = 0
    for row in rows
        (; city, temperature) = row
        rowi += 1
        if mod(rowi, 1000000) == 0
            @info "$rowi rows done"
        end

        # @assert city isa AbstractString "$city"
        # @assert temperature isa AbstractFloat "$temperature"

        records[city] = update(get(records, city, newstats(Float64)), temperature)
        # records[city] = if haskey(records, city)
        #     update(records[city], temperature)
        # else
        #     newstats(temperature)
        # end
    end

    for (city, cs) in records
        println(join((city, cs.mean, cs.std, cs.nsampled), ';'))
    end
end
