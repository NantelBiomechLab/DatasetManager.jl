function write_results(
    filename, df, conds;
    variables=resultsvariables(rs), archive=true, format=:wide
)
    format ∈ (:wide, :long) || throw(ArgumentError("`format` must be either :wide or :long"))
    ("subject", "variable", "value") ∈ names(df) ||
        throw(ArgumentError("`df` must be provided in long format"))
    tempfn = string(filename, '-', bytes2hex(rand(UInt8, 3)))

    if format == :long
        CSV.write(tempfn, df)
        if archive && isfile(filename)
            mv(filename, filename*".bak")
        end
        mv(tempfn, filename)
    else
        wide = unstack(df, [:variable, conds...], :subject, :value)
        open(tempfn, "w") do io
            println(io, join([' '; wide[!, :variable]], ','))
            for cond in conds
                println(io, join([string(cond); wide[!, cond]], ','))
            end

            combined_labels = Matrix(select(wide, conds => ByRow((c...) -> join(c, '_'))))
            println(io, join(combined_labels, ','))

            for sub in sort(unique(df[!,:subject]), lt=natural)
                println(io, join([string(sub);
                    map(x -> ismissing(x) ? "" : string(x), wide[!, string(sub)])], ','))
            end
        end


        if archive && isfile(filename)
            mv(filename, filename*".bak")
        end
        mv(tempfn, filename)
    end
end
