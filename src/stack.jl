"""
    stack(rs::Vector{SegmentResult}, conds; [variables])

Compile the results into a stacked, long form DataFrame
"""
function stack(rs::Vector{SegmentResult{S,ID}}, conds;
    variables=sort(collect(keys(first(rs).results)))
) where {S,ID}
    df = DataFrame(subject = categorical(subject.(rs)))

    for cond in conds
        setproperty!(df, cond, categorical(getindex.(conditions.(rs), cond)))
    end

    for var in variables
        setproperty!(df, var, getindex.(getfield.(rs, :results), var))
    end

    return sort!(DataFrames.stack(df, Not([:subject, conds...])),
        [:variable, :subject, conds...])
end

