function write_results(
    filename, df, conds;
    variables=unique(df.variable), archive=true, format=:wide
)
    format ∈ (:wide, :long) || throw(ArgumentError("`format` must be either :wide or :long"))
    issubset(("subject", "variable", "value"), names(df)) ||
        throw(ArgumentError("`df` must be provided in long format"))
    dir, name = splitdir(filename)
    name, ext = splitext(name)
    tempfn = string(dir, "/~", name, '-', bytes2hex(rand(UInt8, 2)), ext)

    if format == :long
        CSV.write(tempfn, subset(df, :variable => x -> x .∈ Ref(variables)))
        if archive && isfile(filename)
            mv(filename, filename*".bak")
        end
        mv(tempfn, filename)
    else
        wide = unstack(subset(df, :variable => x -> x .∈ Ref(variables)), [:variable, conds...], :subject, :value)
        open(tempfn, "w") do io
            println(io, join([' '; wide[!, :variable]], ','))
            for cond in conds
                println(io, join([string(cond); wide[!, cond]], ','))
            end

            combined_labels = Matrix(select(wide, [:variable; conds] => ByRow((c...) -> join(c, '_'))))
            print(io, "labels,")
            join(io, combined_labels, ',')
            println(io)

            for sub in sort(unique(df[!,:subject]), lt=natural)
                println(io, join([string(sub);
                    map(x -> ismissing(x) ? "" : string(x), wide[!, string(sub)])], ','))
            end
        end


        if archive && isfile(filename)
            mv(filename, filename*".bak"; force=true)
        end
        mv(tempfn, filename)
    end
end
