{
  description = "Workshop-20: barkd — Ark wallet daemon, built the Nix way";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Bark's own flake — provides devShells with the correct Rust toolchain (1.90.0 via fenix)
    bark.url = "github:ark-bitcoin/bark";

    # fenix — up-to-date Rust toolchains for Nix
    # nixpkgs 25.05 ships rustc 1.86.0; bark requires ≥ 1.88. fenix stable is always current.
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, bark, fenix }:
  let
    system = "x86_64-linux";
    pkgs   = import nixpkgs { inherit system; };

    # Rust platform built from fenix stable — satisfies bark's ≥ 1.88 requirement
    rustPlatform = pkgs.makeRustPlatform {
      inherit (fenix.packages.${system}.stable) cargo rustc;
    };

    # ── barkd derivation ──────────────────────────────────────────────────────
    # Builds only the barkd binary from the bark monorepo.
    # src comes directly from the bark flake input — already pinned in flake.lock,
    # no separate fetchFromGitHub needed.
    #
    # HASH: run `nix build .#barkd 2>&1 | grep "got:"` and paste the
    # output value below to replace the placeholder string.
    barkd = rustPlatform.buildRustPackage {
      pname   = "barkd";
      version = "0.1.4";

      src = bark;  # flake input — pinned in flake.lock

      # Hash of the Cargo.lock dependency tree
      cargoHash = "sha256-LCYqflh1TrXVq/P5JO63VpW3Ud13ef8Bt6j76pWWdhs=";

      # bark-rest/build.rs runs `git rev-parse HEAD` to embed a commit hash.
      # The sandbox has no git repo, so we supply GIT_HASH directly.
      GIT_HASH = "0000000000000000000000000000000000000000";

      nativeBuildInputs = with pkgs; [ protobuf clang pkg-config ];
      buildInputs       = with pkgs; [ openssl ];

      # Build only barkd — skip the rest of the workspace
      cargoBuildFlags = [ "--bin" "barkd" ];
      cargoTestFlags  = [ "--bin" "barkd" ];

      meta = with pkgs.lib; {
        description = "Bark wallet daemon — Ark protocol reference implementation (signet only, experimental)";
        homepage    = "https://second.tech/docs/barkd/";
        license     = licenses.asl20;
        platforms   = [ "x86_64-linux" ];
      };
    };

  in
  {
    # ── Part 1: Dev shells ────────────────────────────────────────────────────
    # Re-exported from bark's own flake so you can use them without cloning.
    # `nix develop .#default`  — full dev environment (tests, wasm, slog tools)
    # `nix develop .#build`    — minimal shell, just enough to `cargo build`
    devShells.${system} = {
      default = bark.devShells.${system}.default;
      build   = bark.devShells.${system}.build;
    };

    # ── Part 2: Nix package ───────────────────────────────────────────────────
    # `nix build .#barkd`   — builds barkd into ./result/bin/barkd
    # `nix build`           — same (default)
    packages.${system} = {
      barkd   = barkd;
      default = barkd;
    };

    # ── Part 3: NixOS container ───────────────────────────────────────────────
    # `sudo nixos-container create barkd --flake .#barkd`
    nixosConfigurations.barkd = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.pkgs = pkgs; }
        { _module.args = { inherit barkd; }; }
        ./container-barkd.nix
      ];
    };
  };
}
