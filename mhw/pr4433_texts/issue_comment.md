I ran into this as well (CasADi 3.8.1, MATLAB R2024b, WORHP 1.15, Windows) and tracked it down.

In `WorhpInterface::solve` the callback is guarded by

```cpp
bool firstIteration = true;
...
if (GetUserAction(&m->worhp_c, iterOutput)) {
  if (!firstIteration) {
    firstIteration = true;
    if (!fcallback_.is_null()) { ... fcallback_(...) ... }
  }
  ...
}
```

Since `firstIteration` is initialised to `true` and never set to `false`, the branch is dead code and `iteration_callback` (and hence `opti.callback`) is never evaluated with WORHP. The bug is still present on `main`.

While looking at this I also noticed that WORHP's `stats` contain no `iter_count` (unlike Ipopt), and that `inf_du` is read from `worhp_p.ScaledKKT`, which is a boolean parameter rather than the KKT residual.

I will open a PR that fixes all three.
