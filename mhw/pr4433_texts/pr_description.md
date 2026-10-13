Fixes #4053

This PR fixes three issues in the WORHP interface (`casadi/interfaces/worhp/worhp_interface.cpp`).

### 1. `iteration_callback` is never called

The callback in `WorhpInterface::solve` was guarded by `if (!firstIteration)`, but `firstIteration` was initialised to `true` and never set to `false`, so the callback was never evaluated (#4053). The guard is removed, so the callback is now evaluated at every `iterOutput` action, analogous to Ipopt's `intermediate_callback` (one call per iteration including iteration 0).

The error handling now mirrors `IpoptInterface::intermediate_callback`:
- a nonzero return value terminates the solver (`TerminateError`),
- a `KeyboardInterruptException` terminates the solver,
- other exceptions issue a warning and terminate unless `iteration_callback_ignore_errors` is set.

The timing uses `ScopedTiming`, and `ret_double` is initialised.

### 2. `iter_count` missing in `stats`

`get_stats` only added `return_status`, so `iter_count` (available for Ipopt and other solvers) was missing for WORHP. After the solve, `MajorIter`, `MinorIter`, `NormMax_CV` and `OptiMax` are stored in the memory object and reported as `iter_count`, `iter_minor`, `inf_pr` and `inf_du`.

### 3. Wrong source for `inf_du`

`inf_du` was read from `worhp_p.ScaledKKT`, which is a boolean parameter (so it was always 0 or 1). It now reads `worhp_w.OptiMax`, the optimality value that WORHP prints in its iteration log and in "Final KKT conditions".

### Testing

Tested with CasADi 3.8.1 (plugin rebuilt against the release binaries), MATLAB R2024b, WORHP 1.15, Windows 11:

- The MWE from #4053 now prints the callback output for every iteration (9 calls for 8 iterations), consistent with Ipopt.
- `stats.iter_count` matches "Final values after iteration N" in the WORHP log (16 for a constrained Rosenbrock problem); a second solve with the same `nlpsol` object reports its own count.
- `stats.inf_du` matches "Final KKT conditions" (3.21e-10), `stats.inf_pr` matches "Final constraint violation".
- An `iteration_callback` returning 1 on its 5th call stops WORHP after 4 iterations with `return_status = TerminateError`, `success = 0`.
- An `iteration_callback` that throws behaves identically for Ipopt and WORHP.
- `misc/cpplint.py` with the project's filter settings reports no issues.

I could only test against the real WORHP library on Windows, not against the mockup used in CI.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
