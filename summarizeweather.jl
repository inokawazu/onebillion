using CSV, OnlineStats, DataFrames

const ST{G} = Series{Number,Tuple{Mean{G,EqualWeight},Variance{G,G,EqualWeight}}}

@inline function newstats(T)
    return Series(Mean(T), Variance(T))
end

function (@main)(_)

    # rows = CSV.Chunks("mystats.csv"; header=[:city, :temperature], delim=';', types=[String, Float64])
    chunks = CSV.Chunks("mystats.csv", header=[:city, :temperature], delim=';', types=[String, Float64],
        ntasks=1000)


    ch = Channel(Threads.nthreads()) do c
        foreach(chunk -> put!(c, chunk), chunks)
        while true
            put!(c, nothing)
        end
    end

    tsks = map(1:Threads.nthreads()) do _
        Threads.@spawn begin
            records = Dict{String,ST{Float64}}()
            while true
                chunk = take!(ch)
                isnothing(chunk) && break

                df = DataFrame(chunk)
                # @info "Chuck Data" size=nrow(df)

                for gdf in groupby(df, :city)
                    city = first(gdf.city)
                    if !haskey(records, city)
                        records[city] = newstats(Float64)
                    end
                    fit!(records[city], gdf.temperature)
                end
            end
            records
        end
    end

    total_records = Dict{String,ST{Float64}}()
    for tsk in tsks
        mergewith!(merge!, total_records, fetch(tsk))
    end


    for r in total_records
        println(r)
    end
end
