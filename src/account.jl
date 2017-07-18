type Account
    currency::Currency
    balance::Real
    ledger::TS{Float64}
end

init_ledger() = TS(zeros(Float64,0,3), Vector{Date}(), [:Credit,:Debit,:IsInterest])
Account()::Account = Account(Currency(:USD), 1e6, init_ledger())
Account(currency::Currency)::Account = Account(currency, 1e6, init_ledger())
Account(currency::Currency, balance::Real)::Account = Account(currency, balance, init_ledger())

function show(io::IO, acct::Account)
    println(io, "Account Balance: $(acct.balance) $(acct.currency.asset_id)")
    if (!isempty(acct.ledger))
        println(io, "Credits/Debits:")
        show(io, acct.ledger)
    else
        println(io, "No Credits/Debits Recorded.")
    end
end


