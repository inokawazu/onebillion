using CSV, OnlineStats, DataFrames

const ST{G} = Series{Number,Tuple{Mean{G,EqualWeight},Variance{G,G,EqualWeight}}}

@inline function newstats(T)
    return Series(Mean(T), Variance(T))
end

function csvstream(io, stringtype=String, numbertype=Float64, delim=';', endline='\n', chunk_size=1000000)
    # readuntil(stream::IO, delim; keep::Bool = false)
    Channel() do ch
        while !eof(io)
            city = stringtype[]
            temperature = numbertype[]
            sizehint!(city, chunk_size)
            sizehint!(temperature, chunk_size)
            for _ in 1:chunk_size
                eof(io) && break
                push!(city, readuntil(io, delim))
                push!(temperature, parse(numbertype, readuntil(io, endline)))
            end
            put!(ch, (city=city, temperature=temperature))
        end
    end
end

function (@main)(_)

    # rows = CSV.Chunks("mystats.csv"; header=[:city, :temperature], delim=';', types=[String, Float64])
    # chunks = CSV.Chunks("mystats.csv", header=[:city, :temperature], delim=';', types=[String, Float64], ntasks=1000)

    ch = Channel(Threads.nthreads()) do c
        open("mystats.csv") do io
            foreach(chunk -> put!(c, chunk), csvstream(io))
            while true
                put!(c, nothing)
            end
        end
    end

    tsks = map(1:Threads.nthreads()) do _
        Threads.@spawn begin
            records = Dict{String,ST{Float64}}()
            while true
                chunk = take!(ch)
                isnothing(chunk) && break

                df = DataFrame(chunk)
                @info "Chuck Data" thread=Threads.threadid() size=nrow(df)

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
