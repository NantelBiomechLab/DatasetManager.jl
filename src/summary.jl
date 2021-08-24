"""
    summarize([io,] trials; verbosity=5)

Summarize a vector of `Trial`s.

Summarizes:
- Number of unique subjects and lists IDs
- Total number of trials and trials per subject
- Unique conditions and observed levels, unique combinations of conditions
- Unique sources and source types

# Examples
```julia
julia> summarize(trials)
Subjects:
 └ 15: 1  2  3  4  5  6  7  8  9  10  11  12  13  14  15
Trials:
 ├ Number of trials: 90
 └ Number of trials per subject:
   └ 6: 15/15 (100%)
Conditions:
 ├ Observed levels:
 │ ├ sym => ["asym", "sym"]
 │ └ arms => ["active", "held", "norm"]
 └ Unique level combinations observed: 6 (full factorial)
      sym │   arms │ # trials
    ──────┼────────┼──────────
     asym │ active │ 15
     asym │   held │ 15
     asym │   norm │ 15
      sym │ active │ 15
      ⋮   │   ⋮    │ ⋮
Sources:
 └ "events" => Source{Events}, 90 trials (100%)

```
"""
function summarize(trials::AbstractVector{T}; kwargs...) where T <: Trial
    summarize(stdout, trials; kwargs...)
end

function summarize(io::IO, trials::AbstractVector{T}; verbosity=5) where T <: Trial
    N = length(trials)
    if N === 0
        println(io, "0 trials present")
        return nothing
    end
    subs = sort(unique(subject.(trials)))
    Nsubs = length(subs)
    h, w = displaysize(io)

    # Subjects
    println(io, "Subjects:")
    substr = repr("text/plain", permutedims(subs), context=IOContext(io, :displaysize => (h, w-5), :limit => true))
    println(io, " └ $Nsubs:", split(substr, '\n')[2])

    # Trials
    println(io, "Trials:")
    println(io, " ├ Number of trials: $N")
    println(io, " └ Number of trials per subject:")
    Ntrials= [ count(==(sub) ∘ subject, trials) for sub in subs ]
    maxNtrials = maximum(Ntrials)
    Ntrialsdist = counts(Ntrials, maxNtrials)
    ex = reverse!(findall(!iszero, Ntrialsdist))
    for (j,i) in enumerate(ex[1:min(end,verbosity)])
        num = Ntrialsdist[i]
        str = @sprintf "%i: %i/%i (%2.f%%)" i num Nsubs num/Nsubs*100
        sep = j < min(length(ex),verbosity) ? '├' : '└'
        if j ≥ verbosity
            altstr = @sprintf "≤%i: %i/%i (%2.f%%)" i num Nsubs sum(Ntrialsdist[ex[j:end]]./Nsubs)*100
            println(io, "   $sep ", altstr)
        else
            println(io, "   $sep ", str)
        end
    end

    # Conditions
    obs_levels = Dict( factor => unique(getindex.(conditions.(trials), factor))
        for factor in reduce(vcat, unique(keys.(conditions.(trials)))))
    Nconds = length(obs_levels)

    println(io, "Conditions:")
    println(io, " ├ Observed levels:")
    foreach(enumerate(obs_levels)) do (i, (k, v))
        sep = i === Nconds ? '└' : '├'
        println(io, " │ $sep $k => ", repr(v))
    end

    unq_conds = copy.(unique(conditions.(trials)))
    Nunq_conds = length(unq_conds)
    println(io, " └ Unique level combinations observed: $(Nunq_conds)",
        Nunq_conds === prod(length.(values(obs_levels))) ? " (full factorial)" : "")
    foreach(unq_conds) do conds
        conds[Symbol("# trials")] = count(==(conds), conditions.(trials))
    end
    unq_condsdf = DataFrame(unq_conds)
    unq_condsdf = unq_condsdf[!, [collect(keys(obs_levels)); Symbol("# trials")]]
    sort!(unq_condsdf, order(Symbol("# trials"); rev=true))
    tmpio = IOBuffer()
    pretty_table(tmpio, unq_condsdf; hlines=[:header], display_size=(verbosity+3,w-4),
        vlines=1:ncol(unq_condsdf)-1, alignment=[fill(:r, ncol(unq_condsdf)-1); :l],
        nosubheader=true, crop=:both, newline_at_end=false, show_omitted_cell_summary=false)
    println(io, "    ", replace(String(take!(tmpio)), "\n" => "\n    "))

    # Sources
    println(io, "Sources:")
    srcs = unique(reduce(vcat, collect.(unique(
    broadcast(d -> keys(d) .=> typeof.(values(d)), sources.(trials))))))
    foreach(enumerate(srcs)) do (i, src)
        trialswithsrc = count(x -> hassource(x, src.first), trials)
        sep = i === length(srcs) ? '└' : '├'
        println(io, @sprintf " %s %s, %i trials (%2.f%%)" sep src trialswithsrc trialswithsrc/N*100)
    end


    return nothing
end

