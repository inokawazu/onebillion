using CSV, OnlineStats, DataFrames

const ST{G} = Series{Number,Tuple{Mean{G,EqualWeight},Variance{G,G,EqualWeight}}}

@inline function newstats(T)
    return Series(Mean(T), Variance(T))
end

function (@main)(_)

    chunks = CSV.Chunks("mystats.csv", header=[:city, :temperature], delim=';', types=[String, String], ntasks=1000)

    ch = Channel(Threads.nthreads()) do c
        for chunk in chunks
            put!(c, chunk)
        end
        while true
            put!(c, nothing)
        end
    end

    chunk_count = Threads.Atomic{Int}(0)

    tsks = map(1:max(Threads.nthreads() - 1, 1)) do _
        Threads.@spawn begin
            records = Dict{String,ST{Float64}}()
            # records = GroupBy(String, newstats(Float64))
            while true
                chunk = take!(ch)
                isnothing(chunk) && break
                cn = Threads.atomic_add!(chunk_count, 1)

                df = DataFrame(
                    (city=string(city), temperature=parse(Float64, temperature))
                    for (; city, temperature) in chunk
                )

                @info "Chunk Data" nrows = length(chunk) chunk_number=cn thread = Threads.threadid()

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
