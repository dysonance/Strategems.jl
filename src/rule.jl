immutable struct Rule
    signame::Symbol  # the name of the signal the rule responds to
    sigval::Bool  # the value of signal required to trigger the rule
    action::Union{Order,Void}  # can be either an order or nothing
end
