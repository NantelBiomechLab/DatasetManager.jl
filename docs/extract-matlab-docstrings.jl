using DatasetManager
symbols = []

function matlab_docstr(name, type, docstring, file, lines)
    if type != "Class"
        name = string(basename(splitext(file)[1]), '.', name)
    end
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

for file in readdir(joinpath(pkgdir(DatasetManager), "matlab"))
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
        docstring = replace(docstring,
            r"<a href=\"matlab:web\('(?<url>[^']*)'\)\">(?<text>.*)<\/a>" => s"[\g<text>](\g<url>)",
            r"# (.*)" => s"**\1**")

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


        push!(symbols, (Symbol(name), matlab_docstr(name, type, docstring, joinpath("matlab", file), lines)))
    end
end

open(joinpath(@__DIR__, "src", "matlab-reference.md"), "w+") do io
    println(io, "# MATLAB reference\n")
    println.(io, last.(symbols))
end

nothing

