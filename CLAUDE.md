# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A crypto trading bot / predictor for coins traded on Bitvavo. It polls exchange prices, logs them to CSV,
backtests a rule-based buy/sell strategy against the logged history, and separately experiments with Flux-based
ML models (a binary buy/no-buy classifier and an LSTNet time-series predictor) to try to improve on the rules.

## Julia version pinning (important)

This project's dependency set (`Flux` 0.12, `FluxArchitectures`, CUDA) only resolves under **Julia 1.7.0**, not
the newer default juliaup channel. Package operations and script runs must use Julia 1.7 with an isolated depot:

```bash
export JULIA_DEPOT_PATH="$HOME/.julia-depot-1.7"
julia +1.7.0 --startup-file=no --project -e '...'
```

`bin/install` and `bin/run_julia` already do this correctly — prefer them over invoking `julia` directly.
The root-level `run_julia.sh`, `run_monitor.sh`, `run_mon.sh` are older scripts that source a local `init.sh`
(gitignored, not present in a fresh checkout — it holds API secrets) and do not pin the Julia version; treat
them as legacy/environment-specific rather than the canonical entry points.

## Common commands

Set up the environment (installs Julia 1.7.0 via juliaup if needed, restores the committed default Manifest,
instantiates and precompiles):

```bash
bin/install
```

Start a REPL against the project (uses `MakieSysdev.so` sysimage if present for faster startup):

```bash
bin/run_julia
```

This defines `menu()` in the REPL, which opens an interactive picker (`examples/menu.jl`) over the runnable
scripts in `src/` and `examples/` (it auto-excludes files that are only `include()`d as helpers by another
script).

Run the test suite (loads `status.jld2`, so a prior monitoring/analysis session's state must exist):

```julia
include("test/runtests.jl")
```

Build a custom sysimage (precompiles `TimeZones`/`FluxArchitectures` for faster startup), optionally updating
packages first:

```bash
./create_sys_image.sh [--update]
```

Fetch the latest price logs from the remote server into `data/`:

```bash
./fetch_log.sh
```

## Architecture

**Data collection.** `src/monitor.jl` (Julia, via `PyCall`+`python_bitvavo_api`) or `src/monitor.py` polls the
Bitvavo ticker every 5s and appends one row per minute per active EUR market to `data/log_<unix time>.csv`.

**State and analysis pipeline** (entry point `src/analyze.jl`):
- `load_state()` / `save_state()` (`src/logging.jl`) persist a `State` struct to `status.jld2`, so re-running
  analysis only has to ingest *new* log files, not the whole history.
- `read_log` merges new CSVs into the existing price `DataFrame`, filling minute gaps and interpolating missing
  values (`Impute.jl`) so every market column is a dense time series.
- `State` (`src/basic.jl`) is the central mutable struct: `df` (raw price series), `tdb` (trade ledger),
  `rdb` (current rating table), `rp_table` (price relative to the time each coin was bought), `δ_rating`
  (decaying bonus rating for coins that just spiked), and `index`/`mode` (an `INIT → RATING → MIXED` state
  machine) tracking replay position through `df`.

**Backtesting / trading loop.** `trade(st)` in `src/analyze.jl` replays `df` minute-by-minute via
`check(st)` (`src/check.jl`):
- `on_minute` buys on a fast 1h rise above `MAX_RISE` (or when rating exceeds `MIN_RATING`) and sells on a drop
  below `MIN_DROP`/`MIN_DROP_24` (thresholds in `src/constants.jl`).
- `on_hour` recomputes the rating table.
- every `INTERVAL` hours, `on_some_hours`/`on_some_hours_init` evaluate each held position's performance
  (`src/performance.jl`) since purchase and rotate out underperformers for the top-rated markets.
- A rating (`rating_table` in `src/performance.jl`) is a linear-regression trend (`GLM`) of a market's price
  over the last 1/4 days, scaled by its deviance from that trend (steady risers score higher than volatile ones).
- `src/trade_db.jl` and `src/rel_prices.jl` maintain the trade ledger and the per-market "price relative to
  buy time" table that back these decisions. This whole loop is a **simulation** over historical data — no
  live order placement happens here (`src/trade.jl` is a separate, unrelated CoinMarketCap API exploration).

**ML experiments** (secondary to the rule-based strategy above):
- `src/create_training_data.jl` derives a labeled dataset from `df`: for each minute/market, `RISE_1h`,
  `RISE_24h`, and whether price rose more than `MINRISE`% over the next `PREDICT` hours (the `BUY` label);
  saved to/loaded from `training_db.jld2`.
- `src/predict2.jl` trains a small `Flux` classifier on that dataset (with `FeatureTransforms` mean/std scaling)
  to distinguish `BUY`/non-`BUY` feature distributions.
- `src/predict.jl` / `src/predict_btc.jl` are unrelated experiments using `FluxArchitectures`' `LSTnet` model
  for time-series prediction; `src/predict.py` is a Python-side equivalent.

**Local/generated state (gitignored, not present in a fresh checkout):** `init.sh` (API secrets:
`APIKEY`/`APISECRET` for Bitvavo, `CMC_PRO_API_KEY` for CoinMarketCap), `status.jld2`, `training_db.jld2`,
`Manifest.toml`, `MakieSys*.so` sysimages.
