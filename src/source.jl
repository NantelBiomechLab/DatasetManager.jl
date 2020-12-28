"""
    AbstractSource

In recognition that data sources vary, and the mechanism of reading trials will differ
between data sources, implement a subtype of AbstractSource for your data.
"""
abstract type AbstractSource end

path(s::S) where S <: AbstractSource = s.path

function readsource end

