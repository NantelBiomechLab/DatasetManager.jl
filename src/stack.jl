"""
    stack(rs::Vector{SegmentResult}, conds; [variables])

Compile the results into a stacked, long form DataFrame
"""
function stack(rs::Vector{SegmentResult{S,ID}}, conds;
    variables=sort(collect(keys(first(rs).results)))
) where {S,ID}
    df = DataFrame(subject = subject.(rs))

    for cond in conds
        setproperty!(df, cond, getindex.(conditions.(rs), cond))
    end

    for var in variables
        setproperty!(df, var, getindex.(getfield.(rs, :results), var))
    end

    return DataFrames.stack(df)
end

