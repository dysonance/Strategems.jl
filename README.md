[![Build Status](https://travis-ci.org/dysonance/Strategems.jl.svg?branch=master)](https://travis-ci.org/dysonance/Strategems.jl) [![Coverage Status](https://coveralls.io/repos/dysonance/Strategems.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/dysonance/Strategems.jl?branch=master) [![codecov.io](http://codecov.io/github/dysonance/Strategems.jl/coverage.svg?branch=master)](http://codecov.io/github/dysonance/Strategems.jl?branch=master)

# Strategems
**Strategems** is a [Julia](https://julialang.org/) package aimed at simplifying and streamlining the process of developing, testing, and optimizing algorithmic/systematic trading strategies. This package is inspired in large part by the quantstrat<sup>[1](http://past.rinfinance.com/agenda/2013/workshop/Humme+Peterson.pdf)</sup><sup>,</sup><sup>[2](https://github.com/braverock/quantstrat)</sup> package in [R](https://www.r-project.org/), adopting a similar general structure to the building blocks that make up a *strategy*.

Given the highly iterative nature of event-driven trading strategy development, Julia's high-performance design (particularly in the context of loops) and straightforward syntax would seem to make it a natural fit as a language for systematic strategy research and development. While this package remains early in development, with time the hope is to be able to rapidly implement a trading idea, construct a historical backtest, analyze its results, optimize over a given parameter set, and visualize all of this with great detail.

# Anatomy of a Strategy
Below are the basic building blocks making up the general anatomy of a *Strategy* with respect to the `Strategems.jl` package design and the type definitions used to facilitate the research workflow.
- `Universe`: encapsulation of the assets/securities the strategy is to be allowed to trade
- `Indicator`: calculation done on each asset in the universe whose results we think have predictive potential for future price movement
- `ParameterSet`: inputs/arguments to the indicator calculations
- `Signal`: boolean flag sending messages to the trading logic/rules to be interpreted and acted upon
- `Rule`: applications of trading logic derived from interpretations of prior calculations & signals at each time step
- `Strategy`: overarching object encapsulating and directing all of the above logic and data to power the backtesting engine

# Roadmap / Wish List
* Get a sufficiently full-featured type system established to facilitate easy construction of simple strategies
* Allow more intelligent logic for trading rules
    - Adjust order sizing based on portfolio/account at time $$t$$
    - Portfolio optimization logic
    - Risk limits
    * Stop loss rules
* Define a more diverse set of order types
    - Limit orders
    * Stop orders

