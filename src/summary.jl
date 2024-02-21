unique_sources(trials) = unique(reduce(vcat,
        broadcast(d -> keys(d) .=> typeof.(values(d)), sources.(trials))))

unique_subjects(trials::Vector{Trial{String}}) = sort(unique(subject.(trials)); lt=natural)
unique_subjects(trials::Vector{Trial{I}}) where {I} = sort(unique(subject.(trials)))

unique_conditions(trials) = unique(reduce(vcat, collect.(unique(keys.(conditions.(trials))))))
observed_levels(trials) = Dict( factor => unique(skipmissing(get.(conditions.(trials), factor, missing)))
    for factor in unique_conditions(trials))

function conditions_isequal(condsA, condsB; ignore=nothing)
    if !isnothing(ignore)
        ign_k_condsA = setdiff(keys(condsA), ignore)
        if issetequal(ign_k_condsA, setdiff(keys(condsB), ignore))
            return all(isequal.(getindex.(Ref(condsA), ign_k_condsA),
                getindex.(Ref(condsB), ign_k_condsA)))
        else
            return false
        end
    else
        return isequal(condsA, condsB)
    end
end


"""
    summarize([io,] trials; [verbosity=5, ignoreconditions])

Summarize a vector of `Trial`s.

# Examples

```jldoctest simplefakedata
julia> summarize(trials)
Subjects:
 └ 10: "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10"
Trials:
 ├ 40 trials
 └ Trials per subject:
   └ 4: 10 subjects (100%)
Conditions:
 ├ Observed levels:
 │ ├ stim => ["placebo", "stim"]
 │ └ session => [1, 2]
 └ Unique level combinations observed: 4 (full factorial)
        stim │ session │ # trials
    ─────────┼─────────┼──────────
     placebo │       1 │ 10
        stim │       1 │ 10
     placebo │       2 │ 10
        stim │       2 │ 10
Sources:
 └ "events" => Source{GaitEvents}, 40 trials (100%)

```
"""
function summarize(trials::AbstractVector{T}; kwargs...) where T <: Trial
    summarize(stdout, trials; kwargs...)
end

function summarize(oio::IO, trials::AbstractVector{T};
    verbosity=5, ignoreconditions=nothing
) where T <: Trial
    io = IOBuffer()
    N = length(trials)
    if N === 0
        println(io, "0 trials present")
        print(oio, String(take!(io)))
        return nothing
    end
    subs = unique_subjects(trials)
    Nsubs = length(subs)
    h, w = displaysize(io)
    LG = Crayon(foreground=:light_gray)
    BMGNTA = Crayon(foreground=:magenta, bold=true)
    BLU = Crayon(foreground=:cyan)

    # Subjects
    println(io, BOLD("Subjects:"))
    substr = repr("text/plain", permutedims(subs), context=IOContext(io, :displaysize => (h, w-5), :limit => true))
    println(io, " └ ", BLU("$Nsubs"), ':', LG(split(substr, '\n')[2]))

    # Trials
    println(io, BOLD("Trials:"))
    println(io, " ├ ", BLU("$N"), " trials")
    println(io, " └ Trials per subject:")
    Ntrials= [ count(==(sub) ∘ subject, trials) for sub in subs ]
    maxNtrials = maximum(Ntrials)
    Ntrialsdist = counts(Ntrials, maxNtrials)
    ex = reverse!(findall(!iszero, Ntrialsdist))
    for (j,i) in enumerate(ex[1:min(end,verbosity)])
        num = Ntrialsdist[i]
        plural = num > 1 ? "s" : ""
        sep = j < min(length(ex),verbosity) ? '├' : '└'
        if j ≥ verbosity
            num = sum(Ntrialsdist[ex[j:end]])
            plural = num > 1 ? "s" : ""
            le = num > 1 ? "≤" : ""
            println(io, "   $sep ", BLU("$le$i"), ": $num subject$plural ",
                LG(@sprintf("(%.f%%)", num/Nsubs*100)))
        else
            println(io, "   $sep ", BLU("$i"), ": $num subject$plural ",
                LG(@sprintf("(%.f%%)", num/Nsubs*100)))
        end
    end

    # Conditions
    obs_levels = observed_levels(trials)
    if !isnothing(ignoreconditions)
        foreach(c -> delete!(obs_levels, c), ignoreconditions)
    end
    Nconds = length(obs_levels)

    println(io, BOLD("Conditions:"))
    println(io, " ├ Observed levels:")
    foreach(enumerate(obs_levels)) do (i, (k, v))
        sep = i === Nconds ? '└' : '├'
        println(io, " │ $sep ", BMGNTA("$k"), " => ", repr(v))
    end

    unq_conds = copy.(unique(conditions.(trials)))
    if !isnothing(ignoreconditions)
        foreach(unq_conds) do conds
            foreach(c -> delete!(conds, c), ignoreconditions)
        end
    end
    unq_conds = unique(unq_conds)

    Nunq_conds = length(unq_conds)
    println(io, " └ Unique level combinations observed: ", BLU("$(Nunq_conds)"),
        Nunq_conds === prod(length.(values(obs_levels))) ? LG(" (full factorial)") : "")

    all_conds = unique_conditions(trials)
    foreach(unq_conds) do conds
        conds[Symbol("# trials")] = count(c -> conditions_isequal(conds, c; ignore=ignoreconditions),
            conditions.(trials))
        miss_conds = setdiff(all_conds, keys(conds))
        if !isempty(miss_conds)
            get!.(Ref(conds), miss_conds, missing)
        end
    end
    unq_condsdf = DataFrame(unq_conds)
    unq_condsdf = unq_condsdf[!, [collect(keys(obs_levels)); Symbol("# trials")]]
    sort!(unq_condsdf, order(Symbol("# trials"); rev=true))
    tmpio = IOBuffer()
    pretty_table(IOContext(tmpio, :color => true), unq_condsdf; hlines=[:header], display_size=(verbosity+4,w-4),
        vlines=1:ncol(unq_condsdf)-1, alignment=[fill(:r, ncol(unq_condsdf)-1); :l],
        show_subheader=false, crop=:both, newline_at_end=false, backend=Val(:text),
        header_crayon=[fill(BMGNTA, ncol(unq_condsdf)-1); LG],
        highlighters=Highlighter((v,i,j) -> j === ncol(unq_condsdf), LG),
        formatters=PrettyTables.ft_nomissing,
        show_omitted_cell_summary=false)
    println(io, "    ", replace(String(take!(tmpio)), "\n" => "\n    "))

    # Sources
    println(io, BOLD("Sources:"))
    srcs = unique_sources(trials)
    foreach(enumerate(srcs)) do (i, src)
        trialswithsrc = count(x -> hassource(x, src.first), trials)
        sep = i === length(srcs) ? '└' : '├'
        println(io, " $sep ", GREEN_FG(repr(src.first)), " => $(src.second)", LG(@sprintf(", %i trials (%2.f%%)", trialswithsrc, trialswithsrc/N*100)))
    end

    print(oio, String(take!(io)))

    return nothing
end

