# larp

<!-- three.ws:badges -->
[![GitHub stars](https://img.shields.io/github/stars/nirholas/larp?style=flat&logo=github)](https://github.com/nirholas/larp/stargazers) [![Last commit](https://img.shields.io/github/last-commit/nirholas/larp?style=flat)](https://github.com/nirholas/larp/commits) [![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat)](https://github.com/nirholas/larp/pulls) [![AI agent friendly](https://img.shields.io/badge/AI%20agents-AGENTS.md%20%2B%20llms.txt-6d5dfc?style=flat)](https://github.com/nirholas/larp/blob/HEAD/AGENTS.md)
<!-- /three.ws:badges -->


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

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=nirholas/larp&type=Date)](https://www.star-history.com/#nirholas/larp&Date)

<!-- three.ws:growth -->
## Support the project

If larp saves you time, **[star it on GitHub](https://github.com/nirholas/larp)**. Stars are how other developers and AI agents find the repositories worth trusting, and they cost you one click.

Know someone who would use it? [Post on X](https://twitter.com/intent/tweet?text=larp%3A%20Bash%20utilities%20that%20aggregate%20GitHub%20repo%20contributors%20across%20an%20account%20and%20write%20git%20commits&url=https%3A%2F%2Fgithub.com%2Fnirholas%2Flarp) · [Share on Bluesky](https://bsky.app/intent/compose?text=larp%3A%20Bash%20utilities%20that%20aggregate%20GitHub%20repo%20contributors%20across%20an%20account%20and%20write%20git%20commits%20https%3A%2F%2Fgithub.com%2Fnirholas%2Flarp) · [Share on LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Fgithub.com%2Fnirholas%2Flarp) · [Submit to Hacker News](https://news.ycombinator.com/submitlink?u=https%3A%2F%2Fgithub.com%2Fnirholas%2Flarp&t=larp%3A%20Bash%20utilities%20that%20aggregate%20GitHub%20repo%20contributors%20across%20an%20account%20and%20write%20git%20commits) · [Share on Reddit](https://www.reddit.com/submit?url=https%3A%2F%2Fgithub.com%2Fnirholas%2Flarp&title=larp%3A%20Bash%20utilities%20that%20aggregate%20GitHub%20repo%20contributors%20across%20an%20account%20and%20write%20git%20commits)

## Built for AI agents too

Coding agents and LLM tooling can read this repo directly: [AGENTS.md](./AGENTS.md), [llms.txt](./llms.txt), [llms-full.txt](./llms-full.txt). Point an agent at `https://github.com/nirholas/larp` and it has the context it needs.

## More from the same author

- [All repositories by nirholas](https://github.com/nirholas/nirholas#readme): the full catalog, grouped by topic
- [three.ws](https://three.ws): the platform for 3D AI agents with Solana wallets, a skill marketplace and x402 payments
- Questions or ideas: [open an issue](https://github.com/nirholas/larp/issues) or [start a discussion](https://github.com/nirholas/larp/discussions)

## Contributors

[![Contributors](https://contrib.rocks/image?repo=nirholas/larp)](https://github.com/nirholas/larp/graphs/contributors)

<!-- /three.ws:growth -->
