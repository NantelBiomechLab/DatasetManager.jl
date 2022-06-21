using DatasetManager

function matlab_docstr(name, type, docstring, file, lines)
    article = """
        ```@raw html
        <article class="docstring">
            <header>
                <a id="$name" class="docstring-binding" href="#$name"><code>$name</code></a>
                 —
                <span class="docstring-category">$type</span>
            </header>
            <section>
                <div>
        ```

        $docstring

        ```@raw html
                </div>
                <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/blob/master/$file#L$(first(lines))-L$(last(lines))">source</a>
            </section>
        </article>
        ```
        """
    return article
end

function extract_matlab_docstrings(files=readdir(joinpath(pkgdir(DatasetManager), "matlab")))
    symbols = Dict{Symbol,String}()

    for file in files
        str = read(joinpath(pkgdir(DatasetManager), "matlab", file), String)

        for m in eachmatch(r"(?<name>(?<type>classdef|function) .*)\n(?<docstring>(([\t ]+%[\t ]*.*\n)+))", str)
            isnothing(m) && continue
            type = m[:type] == "classdef" ? "Class" : "Function"
            name_rm = match(r"^(function |classdef )?(\[?(([[:alpha:]]+\w*[[:alpha:][:digit:]])(, ([[:alpha:]]+\w*[[:alpha:][:digit:]]))*)?\]? ?= ?)?(?<symbol_name>[[:alpha:]]+\w*[[:alpha:][:digit:]])", m[:name])
            name = name_rm[:symbol_name]

            beginline = countlines(IOBuffer(SubString(str, 1, m.offset)))
            endline = countlines(IOBuffer(m.match))
            lines = (beginline, endline+beginline-1)
            docstring = replace(m[:docstring], r"(\n?)( {3,}|\t+)% ?" => s"\1")
            docstring = replace(docstring,
                r"^\n?([[:upper:]]+\w*[[:upper:][:digit:]])  " => "")
            # @show docstring
            docstring = replace(docstring,
                r"<a\s+href=\"matlab:web\('(?<url>[^']*)'\)\">(?<text>[\s\S]*?)<\/a>" => s"[\g<text>](\g<url>)",
                r"\[`([[:alpha:]]+\w*[[:alpha:][:digit:]](\.[[:alpha:]]+\w*[[:alpha:][:digit:]])?)`\]\(@ref\)" => s"[`\1`](#\1)",
                r"#+ (.*)" => s"**\1**")

            signatures = match(r"\n\n(?<sigs>(  .*\n)+)", docstring)
            if !isnothing(signatures)
                docstring = replace(docstring, signatures[:sigs] => "")
                sigs = replace(signatures[:sigs], r"(\n?)  " => s"\1")
                docstring = string("```matlab\n", sigs, "```\n", docstring)
            end
            seealso_rgx = r"See also (([[:alpha:]]+\w*[[:alpha:][:digit:]](\.[[:alpha:]]+\w*[[:alpha:][:digit:]])?)(, ([[:alpha:]]+\w*[[:alpha:][:digit:]](\.[[:alpha:]]+\w*[[:alpha:][:digit:]])?))*)"
            seealso = match(seealso_rgx, docstring)
            if !isnothing(seealso)
                seealso_refs = join(("[$sym](#$sym)" for sym in split(seealso[1], ", ")), ", ")
                docstring = replace(docstring, seealso[1] => seealso_refs)
            end

            line1 = readline(joinpath(pkgdir(DatasetManager), "matlab", file))
            if occursin(r"^classdef", line1)
                classm = match(r"^classdef (\S+)", line1)
                namespace = string(classm[1], ".")
            else
                namespace = ""
            end
            fullsym = type == "Class" ? Symbol(name) :
                Symbol(string(namespace, name))

            @info "Found docstring for $fullsym"

            symbols[fullsym] = matlab_docstr(fullsym, type, docstring, joinpath("matlab", file), lines)
        end
    end

    order = Symbol[
        :TrialConditions,
        Symbol("TrialConditions.generate"),
        :DataSubset,
        :Trial,
        Symbol("Trial.findtrials"),
        Symbol("Trial.summarize"),
        Symbol("Trial.analyzetrials"),
        Symbol("SegmentResult.stack"),
        :write_results,
        :Source,
        Symbol("Source.readsource"),
        Symbol("Trial.requiresource"),
        Symbol("Source.generatesource"),
        Symbol("Source.dependencies"),
        Symbol("Source.srcext"),
        Symbol("Source.srcname_default"),
        :Segment,
        Symbol("Segment.readsegment"),
        :SegmentResult,
    ]

    @info "Printing to file $(joinpath(pkgdir(DatasetManager), "docs", "src", "matlab-reference.md"))"
    open(joinpath(pkgdir(DatasetManager), "docs", "src", "matlab-reference.md"), "w+") do io
        println(io, "# MATLAB reference\n")
        foreach(order) do sym
            if haskey(symbols, sym)
                println(io, symbols[sym])
            else
                @warn "Missing docstring for $sym"
            end
        end
    end

    return nothing
end

extract_matlab_docstrings()

