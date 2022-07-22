"""
    stack(rs::Vector{SegmentResult}, conds; [variables])

Compile the results into a stacked, long form DataFrame
"""
function stack(rs::Vector{<:SegmentResult}, conds=unique_conditions(rs);
    variables=resultsvariables(rs)
)
    df = DataFrame(subject = categorical(subject.(rs)))

    for cond in conds
        insertcols!(df, cond => categorical(getindex.(conditions.(rs), cond)))
    end

    for var in variables
        insertcols!(df, var => get.(getfield.(rs, :results), var, missing))
    end

    return sort!(DataFrames.stack(df, Not([:subject, conds...])),
        [:variable, :subject, conds...])
end

stack(rs::Vector{<:SegmentResult}, conds::TrialConditions; kwargs...) = stack(rs, filter(!=(:subject), conds.condnames); kwargs...)

function flatten_dims(df, col; axes=["X","Y","Z"])
    df.axis = fill(categorical(string.(axes)), nrow(df))
    flatten(df, [col, :axis])
end

