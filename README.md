---
layout: default
title: Home
nav_order: 1
---

# NixOS Platform Management Workshops

Understanding how a NixOS system is managed through practical examples of declarative systems configuration, reproducible deployments, container orchestration and more.

## Workshops

| Workshop | Description |
|----------|-------------|
| [Workshop O](./workshop-0/) | **Install NixOS from factory bootable installation USB stick.** - In 30 minutes set up your first NisOS using the official distribution bootable installer (follow-up is [Workshop 5](./workshop-5/ where we do the same thing but with your custom installation media)) |
| [Workshop 1](./workshop-1/) | **Run NixOS in a VM or a container** - In 5 minutes set up your first "machine in your machine" |
| [Workshop 2](./workshop-2/) | **Configure Services Declaratively** - In 2 minutes deploy services using NixOS configuration (bitcoin)
| [Workshop 3](./workshop-3/) | **Override System Packages** - In 10 minutes customize your NixOS platform using Nix package overrides (Fast, No Compilation)|
| [Workshop 4](./workshop-4/) | **Deploy Integrated Stacks** - In 10 minutes use pre-built NixOS modules (in this example `nix-bitcoin`) to improve setup and maintainability (follow-up is [Workshop 11](./workshop-11/ where we do the same thing from source))|
| [Workshop 5](./workshop-5/) | **Build Your Custom Installation Media** - In 5 Minutes Create pre-configured NixOS installation media with SSH configuration and other basic settings|
| [Workshop 6](./workshop-6/) | **Manage NixOS Containers via CLI** - Create and manage containers independently imperatively (as opposed to declaratively) |
| [Workshop 8](./workshop-8/) | **Proposed Lab Setup** - With focus on DHCP, DNS, and NAT for container infrastructure |
| [Workshop 9](./workshop-9/) | **Containers Management in NixOS (nix-bitcoin, REGTEST)** - Deploy complex services across containers and demonstrate how they interact |
| [Workshop 10](./workshop-10/) | **Mutinynet on a VM and other nix-bitcoin on a Container** - How to run Mitinynet (a fork of bitcoin to run on Muninynet's SIGNET), Deploy complex services across containers and demonstrate how they interact |
| [Workshop 11](./workshop-11/) | **Compile Packages from Source with fetchFromGitHub** - Compile from source approach to package overrides using `fetchFromGitHub` and `overrideAttrs` (follow-up of [Workshop 4](./workshop-4/) where we used cached, precompiled packages, pre-build modules)|


## Getting Started

Start with [Workshop 1](./workshop-1/) to set up your NixOS environment, then progress through the workshops in order. Each workshop builds on concepts from previous ones.

## Prerequisites

- Basic Linux command-line knowledge
- A machine capable of running virtual machines (8GB+ RAM recommended)
- If you're not in the mood, pick a book from our list in [baby-rabbit-holes#books](./baby-rabbit-holes.md#books) and come back when you're ready


