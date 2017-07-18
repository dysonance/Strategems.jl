const ACCT_BAL_DEFAULT = 1e6

mutable struct Ledger
    credits::Vector{Float64}
    debits::Vector{Float64}
    is_interest::Vector{Bool}
end

mutable struct Account
    currency::Currency
    balance::Float64
    ledger::Ledger
end

#init_ledger() = TS(zeros(Float64,0,3), Vector{Date}(), [:Credit,:Debit,:IsInterest])
init_ledger(init_bal::Float64=ACCT_BAL_DEFAULT)::Ledger = Ledger([init_bal], [0.0], [false])

function set_balance!(acct::Account)::Void
    acct.balance = sum(acct.ledger.credits) - sum(acct.ledger.debits)
    return nothing
end

Account()::Account = Account(Currency(:USD), ACCT_BAL_DEFAULT, init_ledger())
Account(currency::Currency)::Account = Account(currency, ACCT_BAL_DEFAULT, init_ledger())
Account(currency::Currency, balance::Float64)::Account = Account(currency, balance, init_ledger())

function show(io::IO, acct::Account)
    println(io, "Account Balance: $(acct.balance) $(acct.currency.asset_id)")
    if (!isempty(acct.ledger))
        println(io, "Credits/Debits:")
        show(io, [acct.ledger.credits acct.ledger.debits])
    else
        println(io, "No Credits/Debits Recorded.")
    end
end


