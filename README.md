[![Build Status](https://travis-ci.org/dysonance/Strategems.jl.svg?branch=master)](https://travis-ci.org/dysonance/Strategems.jl) [![Coverage Status](https://coveralls.io/repos/dysonance/Strategems.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/dysonance/Strategems.jl?branch=master) [![codecov.io](http://codecov.io/github/dysonance/Strategems.jl/coverage.svg?branch=master)](http://codecov.io/github/dysonance/Strategems.jl?branch=master)

# Strategems
**Strategems** is a Julia package aimed at simplifying and streamlining the process of developing, testing, and optimizing algorithmic/systematic trading strategies. This package is inspired in large part by the [quantstrat](http://www.rinfinance.com/agenda/2013/workshop/Humme+Peterson.pdf) package in [R](https://www.r-project.org/), adopting a similar general structure to the building blocks that make up a *strategy*.

Given the highly iterative nature of event-driven trading strategy development, Julia's high-performance design (particularly in the context of loops) and straightforward syntax would seem to make it an ideal language for strategy development. While this package remains early in development, with time the hope is to be able to rapidly implement a trading idea, construct a historical backtest, analyze its results, optimize over a given parameter set, and visualize all of this with great detail.

## Anatomy of a Strategy
The basic building blocks of a trading strategy are as follows:
- **Data**: asset universe on which a test is conducted
- **Calculations/Indicators**: computations done on each asset in the universe
    - **Parameter Sets**: inputs/arguments to these computations
        - *Value*: a single default input for the initial test (potentially a hypothesized optimal value)
        - *Space*: a range of values a given parameter is allowed to take on while running an optimization
- **Signals**: boolean flags sending messages to the trading logic/rules to be interpreted and acted upon
- **Rules**: applications of trading logic derived from interpretations of prior calculations & signals at each time step
    - *Entry*: opening of a new position of a specified quantity in a given asset (going long or short)
    - *Exit*: closing of some portion of a pre-existing position in a given asset
- **Strategies**: amalgamations of data, calculation instructions, signal generators, and logical rules that dictate trading decisions
    - *Backtests*: perform all calculations, generate all signals, and apply all rules to each asset in the universe over history
    - *Optimizations*: systematically perform a series of backtests using different inputs (i.e. parameter sets, stop loss levels, trading rules, portfolio management techniques)
