using CSV, DataFrames, Random


function (@main)(args)
    target_rows = if isempty(args)
        1_000_000
    else
        parse(Int, only(args))
    end

    (; city, temperature) = CSV.read(
        "weather_stations.csv",
        DataFrame,
        header=["city", "temperature"],
    )
    rows_printed = 0
    while rows_printed <= target_rows
        for (c, t) in zip(city, temperature)
            println(c, ';', round(t + 10*randn(), digits = 6))
            rows_printed += 1
        end
    end
end
