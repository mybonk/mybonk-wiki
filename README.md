---
layout: default
title: Home
nav_order: 1
---

# NixOS Platform Management Workshops

Understanding how a NixOS system is managed through practical examples of declarative systems configuration, reproducible deployments, container orchestration and more.

## Getting Started

Start with [Workshop 1](./workshop-1/) to set up your NixOS environment, then progress through the workshops in order. Each workshop builds on concepts from previous ones.

## Prerequisites

- Basic Linux command-line knowledge
- A machine capable of running virtual machines (8GB+ RAM recommended)
- If you're not in the mood, pick a book from our list in [baby-rabbit-holes#books](./baby-rabbit-holes.md#books) and come back when you're ready

## Workshops

| Workshop | Description |
|----------|-------------|
| [Workshop 0](./workshop-0/) | **Own your OS: Install NixOS from a bootable USB in 30 minutes** - Set up your first NixOS using the official distribution bootable installer (follow-up is [Workshop 5](./workshop-5/) where we do the same thing but with your custom installation media) |
| [Workshop 1](./workshop-1/) | **Own your first machine-in-a-machine: NixOS in a VM or container in 5 minutes** - Set up your first "machine in your machine" |
| [Workshop 2](./workshop-2/) | **Own your services: Deploy Bitcoin declaratively in 2 minutes** - Deploy services using NixOS declarative configuration |
| [Workshop 3](./workshop-3/) | **Own your packages: Override any NixOS package — no recompile needed** - Customize your NixOS platform using Nix package overrides in 10 minutes |
| [Workshop 4](./workshop-4/) | **Own your Bitcoin stack: nix-bitcoin in 10 minutes** - Use pre-built NixOS modules to deploy a full Bitcoin stack with `nix-bitcoin` (follow-up is [Workshop 11](./workshop-11/) where we do the same thing from source) |
| [Workshop 5](./workshop-5/) | **Own your installer: Build a custom NixOS USB in 5 minutes** - Create pre-configured NixOS installation media with SSH and other basic settings |
| [Workshop 6](./workshop-6/) | **Own your containers: Manage NixOS containers from the CLI** - Create and manage containers independently and imperatively (as opposed to declaratively) |
| [Workshop 7](./workshop-7/) | **Own your metrics: Container dashboards with Prometheus and Grafana** - Add a real-time dashboard showing CPU, memory, disk, and network metrics for every container; no new files — uncomments the monitoring blocks already present in workshop-6 |
| [Workshop 8](./workshop-8/) | **Own your lab network: DHCP, DNS and NAT for container infrastructure** - Proposed lab setup with focus on DHCP, DNS, and NAT |
| [Workshop 9](./workshop-9/) | **Own your regtest: nix-bitcoin services across containers** - Deploy complex services across containers and demonstrate how they interact |
| [Workshop 10](./workshop-10/) | **Own your signet: Bitcoin VM + Lightning container on Mutinynet** - Run Mutinynet (a Bitcoin fork with 30-second blocks), deploy complex services across containers and demonstrate how they interact |
| [Workshop 11](./workshop-11/) | **Own your builds: Compile any package from source with Nix** - Compile from source using `fetchFromGitHub` and `overrideAttrs` (follow-up of [Workshop 4](./workshop-4/) where we used cached, precompiled packages) |
| Workshop 12 | |
| Workshop 13 | |
| Workshop 14 | |
| Workshop 15 | |
| Workshop 16 | |
| Workshop 17 | |
| Workshop 18 | |
| [Workshop 19](./workshop-19/) | **Own your recovery: Destroy and restore your Bitcoin and Lightning node** - Deliberately destroy and restore data at the Bitcoin and Lightning layers; learn what to back up, the hierarchy of Lightning recovery, and how to verify a recovery is genuine |
| [Workshop 20](./workshop-20/) | **Own your Ark wallet: Build and run barkd the Nix way** - Build the Ark protocol wallet daemon from a Rust workspace using `buildRustPackage` and run it as a NixOS container service |
| [Workshop 21](./workshop-21/) | **Own your Lightning plugins: The NixOS way** - Two methods: nix-bitcoin native (`monitor`) vs. direct CLN store-path loading (`bookkeeper`); understanding why the difference exists |
| [Workshop 22](./workshop-22/) | **Own your treasury: 3-of-5 multisig** - The most important Bitcoin security primitive for organisations; model a 5-partner treasury company, run a signing ceremony in Sparrow Wallet, and stress-test the policy with a simultaneous resignation and death scenario |
| [Workshop 23](./workshop-23/) | **Own your versions: Bitcoin stack compatibility and safe upgrades** - Why version drift is dangerous in Bitcoin infrastructure; CLN × Bitcoin Core compatibility matrix; forward-only DB migrations; how to inspect, pin, and advance versions using nixpkgs channels and `nix flake lock` |
| [Workshop 30](./workshop-30/) | **Own your Nostr relay in 5 minutes** - What Nostr is and why it matters; spin up a `nostr-rs-relay` container; generate keys, publish notes, broadcast to multiple relays simultaneously, and federate with a public relay using `nak sync` (NIP-77 negentropy) |


