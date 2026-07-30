# larp

Two bash utilities for working with GitHub contributor identities, plus the data they
produced.

`fetch-contributors.sh` reads every repo of a GitHub account or org and aggregates the
contributor list across all of them. `commit-push.sh` writes a git commit under a chosen
identity, resolving that account's GitHub noreply email so the commit attributes
correctly, and `run-all.sh` drives it over a batch of identities.

There is nothing to build and no dependency install. Everything here is a shell script.

## Requirements

- `bash` 4+ (the scripts use associative arrays)
- [`gh`](https://cli.github.com/), authenticated with `gh auth login`
- `jq`
- `curl` and `git`

## fetch-contributors.sh

Aggregates contributors across every repo owned by one account or org.

```bash
./fetch-contributors.sh nirholas
./fetch-contributors.sh bnb-chain --format json --output contributors.json
./fetch-contributors.sh nirholas --format csv --output contributors.csv --include-forks
```

| Flag | Meaning |
|---|---|
| `--format <json\|csv\|table>` | Output shape. Default `table`. |
| `--output <file>` | Write to a file instead of stdout. |
| `--include-forks` | Also count forked repos. Off by default. |
| `-h`, `--help` | Print usage and exit. |

Progress goes to stderr, results to stdout, so redirecting stdout gives you clean data.
The `table` and `json` formats group by contributor and sort by total contributions;
`csv` emits one row per contributor per repo.

The two JSON files checked in here (`binance-contributors.json`,
`bnbchain-contributors.json`) are saved output from earlier runs of this script.

## commit-push.sh

Commits as a registered identity. The `ACCOUNTS` array near the top of the file maps a
short key to a GitHub username; the script resolves that username's numeric GitHub ID
through the public API and commits with `<id>+<username>@users.noreply.github.com`.
Resolved IDs are cached under `$XDG_CACHE_HOME/commit-push` (or `~/.cache/commit-push`).

```bash
./commit-push.sh --list                     # show registered identities
./commit-push.sh n -m "🐛 fix bug"          # commit as a registered shortcut
./commit-push.sh @octocat -m "hello"        # commit as any GitHub user
./commit-push.sh n -m "wip" --no-push       # commit without pushing
./commit-push.sh --clear-cache              # drop cached GitHub IDs
```

Anything that is not `--no-push` is forwarded straight to `git commit`, so the usual
flags (`-m`, `--amend`, `-S`) work. Without `--no-push` the script pushes the current
branch to `origin` after committing.

Note that `resolve_email` calls `api.github.com` unauthenticated, which is rate limited
to 60 requests per hour. The cache means each username costs one request ever, but a
first run over a large identity list will hit the limit; those lookups fall back to
`<username>@users.noreply.github.com`.

## run-all.sh

Appends a line to `contributions.log` and calls `commit-push.sh` once per shortcut in
its `SHORTCUTS` array, continuing past failures. Every shortcut it lists is registered
in `commit-push.sh`. It pushes on each iteration, so read it before running it.

`contributions.log` and `bnb-contributions.log` are the run logs from previous batches.

## License

All rights reserved. See [LICENSE](LICENSE).

## Documentation

Full documentation site: **https://nirholas.github.io/larp/**

- [Getting started](docs/getting-started.md) covers install and first run.
- [Examples](docs/examples.md) has copy-paste snippets.
