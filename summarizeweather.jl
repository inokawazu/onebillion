using CSV, OnlineStats, DataFrames

const ST{G} = Series{Number,Tuple{Mean{G,EqualWeight},Variance{G,G,EqualWeight}}}

@inline function newstats(T)
    return Series(Mean(T), Variance(T))
end

function (@main)(_)

    #     rows = CSV.Rows("mystats.csv"; reusebuffer = true, header=[:city, :temperature], delim=';', types=[Symbol, Float64])
    #     o = GroupBy(Symbol, newstats(Float64))
    #     fit!(o, (city => temperature for (; city, temperature) in rows))

    chunks = CSV.Chunks("mystats.csv", header=[:city, :temperature], delim=';', types=String, ntasks=1000)
    # chunks = CSV.Chunks("mystats.csv", header=[:city, :temperature], delim=';', types=[String, Float64], ntasks=1000)

    ch = Channel(Threads.nthreads()) do c
        for chunk in chunks
            put!(c, chunk)
        end

        while true
            put!(c, nothing)
        end
    end

    tsks = map(1:Threads.nthreads()) do _
        Threads.@spawn begin
            records = Dict{String,ST{Float64}}()
            # records = GroupBy(Symbol, newstats(Float64))
            while true
                chunk = take!(ch)
                isnothing(chunk) && break

                df = DataFrame(
                    (city=city, temperature=parse(Float64, temperature))
                    for (; city, temperature) in chunk
                )

                @info "Chunk Data" thread = Threads.threadid() size = nrow(df)

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
