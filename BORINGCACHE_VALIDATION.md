# BoringCache validation, 9 September 2026

The cold/warm comparison and all five source changes passed their selected
workloads. This fork compares BoringCache One v1.21.0 through GitHub OIDC with Oxid's pinned
sccache 0.17.0 GitHub backend. It runs the existing `./run.sh unit --strict` and
`./run.sh ui --strict` workloads inside their locked `ci-rust` and `ci-ui` Nix
shells. Each unit job passes 567 tests, with 7 ignored; each UI job passes 124.
Headless integration, coverage, release, quality, Nix package and live/platform
workflows are outside this comparison.

The measured source starts at upstream `8c2affc` and applies five original
first-parent commits through `259cc8c`, one at a time. The last measured fork
commit is [14691a6](https://github.com/boringcache/oxid/commit/14691a62245ba50020aa9db9e3fc9d431e911323).
Its source matches that upstream tip outside the six onboarding files. This
report and a final blank-line cleanup are committed separately with `[skip ci]`;
that measured head is unchanged. The five changes do not alter the Rust source or dependencies compiled by
the selected workloads, so they test continued reuse rather than invalidation
after a compiled-source change.

| Run | Result |
| --- | --- |
| [Initial cold seeds](https://github.com/boringcache/oxid/actions/runs/34315575517) | Four cold jobs passed; warm jobs were cancelled after diagnosing the empty GitHub cache. |
| [Corrected fresh comparison](https://github.com/boringcache/oxid/actions/runs/34317722510) | Repaired GitHub seeds and four fresh read-only jobs passed; existing BoringCache seeds were retained. |
| [Change 1](https://github.com/boringcache/oxid/actions/runs/34320979559) | Four jobs passed. |
| [Change 2](https://github.com/boringcache/oxid/actions/runs/34321675487) | Four jobs passed. |
| [Change 3](https://github.com/boringcache/oxid/actions/runs/34322480952) | Four jobs passed. |
| [Change 4](https://github.com/boringcache/oxid/actions/runs/34323328663) | Four jobs passed. |
| [Change 5](https://github.com/boringcache/oxid/actions/runs/34324090224) | Four jobs passed. |

The fresh pairs used matching CPU models within each workload: EPYC 9V74 for
unit and EPYC 7763 for UI, each with four logical CPUs.

| Fresh workload | BoringCache command / job | GitHub command / job | BoringCache hits / misses | GitHub hits / misses |
| --- | ---: | ---: | ---: | ---: |
| Unit | 204.94s / 278s | 276.16s / 328s | 1,037 / 0 | 1,008 / 29 |
| UI/application | 363.22s / 433s | 426.13s / 494s | 2,423 / 0 | 2,403 / 20 |

BoringCache used 25.8% less unit command time and 14.8% less UI command time in
these individual fresh pairs. The differences include both storage transfer and
the cost of recompiling GitHub's missing seed objects.

On change 5, both unit runners used EPYC 7763 and both caches hit every cacheable request.
BoringCache took **255.89s command / 333s job**; GitHub took **281.99s / 337s**.
That is 9.3% less command time but only four seconds less full-job time. CPU
models vary in other later pairs, and GitHub unit was faster in change 3. These
runs do not establish one general backend speedup. Native statistics, command
timing, CPU details and workload logs are retained in each run's artifacts.

The initial GitHub configuration selected cache API v1 and failed every compiler
write. A [diagnostic compiling one C object](https://github.com/boringcache/oxid/actions/runs/34317224996)
reported HTTP 404/NotFound. Exporting `ACTIONS_CACHE_SERVICE_V2=true` enabled a
[write and a hit on a fresh read-only runner](https://github.com/boringcache/oxid/actions/runs/34317488769).
The captured upstream workflow lacks this selector. The repaired full seeds
still reported 29 unit and 51 UI write errors of unknown HTTP class. Change 1's
trusted unit job filled its 29 missing objects with zero write errors; later unit
jobs restored all 1,037 requests. UI remains read-only and misses 20 Rust objects.
Read-only write errors after those misses are expected under that policy.

UI seeding is an explicit policy experiment on both providers. Upstream permits
only trusted unit writers. Rolling jobs restore that unit-write/UI-read-only
policy while retaining the experimental UI seeds. Compiler namespaces are
separate by workload. No Cargo target/download or Nix store archive is restored.
Cold labels describe the first measured use of these namespaces; re-running the
manual workflow will reuse their contents.

BoringCache's completed fresh read-only and rolling jobs report zero native compiler
misses and zero cache read/write errors or timeouts. Both providers still report
other cache errors and compiler failures: 5 and 6 for unit, 19 and 7 for UI.
These are separate counters; the results do not claim zero total errors.

After the fifth BoringCache unit writer, the cache UI still displayed 1,034 live
unit keys / **667 MB** and 2,055 live UI keys / **1000 MB**, matching the seed.
Unit advanced from version 1 to 6; UI remained at version 1. The five publications
did not increase those observed key counts or rounded sizes. Exact physical-byte
growth is unavailable. These literal BoringCache UI labels are not compared with
GitHub's exact API byte counts to claim compression or storage savings.

Initial GitHub full-job times include a 600-second daemon/pipe delay in the
benchmark wrapper and are excluded from provider timing comparisons. Their inner
command timings remain valid. The corrected and rolling wrapper explicitly stops
the GitHub daemon after collecting native statistics. One owns its own daemon.
No upstream pull request, issue comment, outreach or deployment was made.
