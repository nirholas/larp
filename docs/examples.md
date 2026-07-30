# larp examples

Two bash utilities for working with GitHub contributor identities, plus the data they produced.

## Example 1

```bash
./fetch-contributors.sh nirholas
./fetch-contributors.sh bnb-chain --format json --output contributors.json
./fetch-contributors.sh nirholas --format csv --output contributors.csv --include-forks
```

## Example 2

```bash
./commit-push.sh --list                     # show registered identities
./commit-push.sh n -m "🐛 fix bug"          # commit as a registered shortcut
./commit-push.sh @octocat -m "hello"        # commit as any GitHub user
./commit-push.sh n -m "wip" --no-push       # commit without pushing
./commit-push.sh --clear-cache              # drop cached GitHub IDs
```


Every snippet above is taken from the [repository documentation](https://github.com/nirholas/larp#readme).
