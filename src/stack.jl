"""
    stack(rs::Vector{SegmentResult}, conds; [variables])

Compile the results into a stacked, long form DataFrame
"""
function stack(rs::Vector{<:SegmentResult}, conds;
    variables=resultsvariables(rs)
)
    df = DataFrame(subject = categorical(subject.(rs)))

    for cond in conds
        insertcols!(df, cond => categorical(getindex.(conditions.(rs), cond)))
    end

    for var in variables
        insertcols!(df, var => getindex.(getfield.(rs, :results), var))
    end

    return sort!(DataFrames.stack(df, Not([:subject, conds...])),
        [:variable, :subject, conds...])
end

stack(rs::Vector{<:SegmentResult}, conds::TrialConditions; kwargs...) = stack(rs, conds.condnames; kwargs...)

