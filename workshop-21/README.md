# Workshop 21: Own your Lightning plugins: The NixOS way

## Overview

Core Lightning has a rich plugin ecosystem. Under NixOS/nix-bitcoin there are **two distinct ways** to enable a plugin, and understanding the difference matters:

| Method | When to use | Example |
|--------|-------------|---------|
| `services.clightning.plugins.<name>.enable = true` | Plugin packaged and maintained by nix-bitcoin | `monitor` |
| `plugin=<store-path>` in `extraConfig` | Bundled with CLN but not exposed by nix-bitcoin | `bookkeeper` |

This workshop demonstrates both methods using `monitor` and `bookkeeper` as concrete examples.

**Prerequisites:**
- [Workshop 10](../workshop-10/) — must be fully working: Bitcoin VM running, `lightning` container up, CLN connected to bitcoind

---

## Background: Why Two Methods?

nix-bitcoin packages a curated set of CLN plugins and exposes them as NixOS options. When you use `plugins.<name>.enable = true`, nix-bitcoin handles fetching, storing, and injecting the correct `plugin=` path into CLN's config automatically.

Some useful plugins are **not exposed by nix-bitcoin** even though they ship inside the `clightning` package itself. For those, you reference their path directly in `extraConfig` using `${pkgs.clightning}` — the Nix store path of the CLN package — which is fully reproducible and requires no hardcoded paths.

---

## Part 1: `monitor` — nix-bitcoin Native Plugin

`monitor` is a lightweight watchdog that runs inside CLN and periodically checks node health metrics: channel states, peer connectivity, and whether your node is keeping up with the chain. It does not store any data of its own — it only reads CLN's internal state and emits log warnings when thresholds are crossed. Think of it as an always-on sanity check that surfaces problems in `journalctl` before they become outages.

In `workshop-10/container-lightning.nix` the line is already present — just ensure it is uncommented:

```nix
services.clightning = {
  # ...
  # ── Workshop-21: nix-bitcoin native plugin ──────────────────────────────
  plugins.monitor.enable = true;
  # ────────────────────────────────────────────────────────────────────────
  # ...
};
```

Apply:

```bash
sudo ./manage-containers.sh update lightning
```

Verify:

```bash
sudo nixos-container run lightning -- \
  lightning-cli --network=signet plugin list | jq '.plugins[] | select(.name | test("monitor"))'
```

---

## Part 2: `bookkeeper` — Built-in Plugin, Always Active

`bookkeeper` is a full double-entry accounting plugin shipped inside the CLN binary itself. It hooks into CLN's internal event stream and records every satoshi movement — channel open/close costs, routing fees earned, payments sent and received — into a dedicated SQLite database at `/var/lib/clightning/signet/accounts.sqlite3`. Unlike the raw CLN database which focuses on channel state, bookkeeper gives you a clean income/expense ledger queryable via `bkpr-*` commands.

Released in **February 2025 as part of CLN 25.02**, bookkeeper graduated from an optional community plugin to a **fully integrated part of Core Lightning**. As of that release it loads automatically with no configuration — not via nix-bitcoin, not via `extraConfig`. It is simply always there. This is itself an instructive point: not every plugin needs to be enabled; some ship active by default and only need to be *used*.

Verify it is running:

```bash
sudo nixos-container run lightning -- \
  lightning-cli --network=signet plugin list | jq '.plugins[] | select(.name | test("bookkeeper"))'
```

Explore — all commands run from the host:

```bash
# Every recorded satoshi event: channel opens, closes, payments, routing fees
lightning-cli --network=signet bkpr-listaccountevents | jq

# Current balance per account (wallet, channel, fees)
lightning-cli --network=signet bkpr-listbalances | jq

# Income statement: what came in vs. what went out
lightning-cli --network=signet bkpr-listincome | jq

# APY per channel — useful for evaluating routing performance
lightning-cli --network=signet bkpr-channelsapy | jq

# Export income as CSV for spreadsheet or tax tool import
lightning-cli --network=signet bkpr-dumpincomecsv koinly       # Koinly format
lightning-cli --network=signet bkpr-dumpincomecsv cointracker  # CoinTracker format

# Inspect a channel account in detail — get a channel ID from bkpr-listbalances first
CHAN=$(lightning-cli --network=signet bkpr-listbalances | jq -r '.accounts[] | select(.account_type == "channel") | .account' | head -1)
lightning-cli --network=signet bkpr-inspect "$CHAN" | jq

# Add a human-readable label to an event
lightning-cli --network=signet bkpr-editdescriptionbypaymentid <payment_id> "rebalance to peer X"
```

> On a fresh node with no activity most results will be empty — open a channel or make a payment first, then re-run to see bookkeeper in action.

---

## Disabling a Plugin

**nix-bitcoin plugin:** comment out the `plugins.<name>.enable = true` line and update.

**Store-path plugin:** comment out the `plugin=` line in `extraConfig` and update.

Both take effect via `sudo ./manage-containers.sh update lightning` — no container destroy needed.

---

## Troubleshooting

**Plugin listed but crashes on startup:**
```bash
sudo nixos-container run lightning -- \
  journalctl -u clightning -n 50 | grep -i "plugin\|error\|failed"
```

**`bookkeeper` not appearing in plugin list:**
It is built-in from CLN 25.02 onwards. If missing, your CLN version predates it. Check:
```bash
sudo nixos-container run lightning -- lightning-cli --network=signet getinfo | jq '.version'
```

**`monitor` option rejected during rebuild:**
nix-bitcoin may have removed it in a newer revision. Check available plugin options:
```bash
nix eval .#nixosConfigurations.lightning.options.services.clightning.plugins --json 2>/dev/null | jq 'keys'
```

---

## References

- [Workshop 10: Bitcoin VM + Lightning Container](../workshop-10/)
- [nix-bitcoin — clightning module](https://github.com/fort-nix/nix-bitcoin/blob/master/modules/clightning.nix)
- [CLN bundled plugins source](https://github.com/ElementsProject/lightning/tree/master/plugins)
- [bookkeeper documentation](https://docs.corelightning.org/docs/bookkeeper)
