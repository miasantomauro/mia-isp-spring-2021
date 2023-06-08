# Cryptography

## TODO (2023)

- performance of version in 2023 Forge (100 seconds per run is an OOM slower)
- ns test
- ns fixed test
- reflect test
  - TypeError: r is undefined (viz)
    - this is a _Forge_ bug: Skolem relations are being sent with unary type, even if skolem depth > 1. 
- blanchet test
- blanchet corrected test
- documentation in this file
- document predicates (temporary? wellformed? can we rename the former to something meaningful?)
- fully migrate tests and docs to Forge repo
- Need better built-ins (right now there are many query helpers the user has to write)
  - this goes to the educational focus! simplify the support, perhaps...
- Need better error if someone uses "not" instead of "!" in forge/core

## ...

A Model to produce a standard crypto visualization.

## crypto.rkt

The forge model

## crypto.js

renders the visualization

Requires:

* Stage: \<svg\>
* Libraries:
  * D3
  