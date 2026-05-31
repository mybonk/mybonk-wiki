# Nostr relay configuration
# Adds nostr-rs-relay and nak on top of the workshop-6 base container.
# nostr-rs-relay has no NixOS module — this file wires it as a custom systemd service.

{ config, pkgs, lib, ... }:

let
  relayPort = 7777;
  dataDir   = "/var/lib/nostr-rs-relay";

  # Config is written to the Nix store and symlinked into the working directory
  # at service start. nostr-rs-relay reads config.toml from its CWD.
  relayConfig = pkgs.writeText "nostr-rs-relay.toml" ''
    [info]
    relay_url = "ws://0.0.0.0:${toString relayPort}"
    name      = "Workshop-30 Relay"
    description = "MYBONK Nostr workshop relay"

    [network]
    port    = ${toString relayPort}
    address = "0.0.0.0"

    [database]
    data_directory = "${dataDir}"
    engine         = "sqlite"

    [limits]
    messages_per_sec     = 100
    subscriptions_per_min = 60
  '';
in
{
  # nak: command-line tool for Nostr (key generation, event publishing, relay sync)
  environment.systemPackages = [ pkgs.nak ];

  users.users.nostr-relay = {
    isSystemUser = true;
    group        = "nostr-relay";
  };
  users.groups.nostr-relay = {};

  systemd.services.nostr-relay = {
    description = "Nostr relay (nostr-rs-relay)";
    after       = [ "network.target" ];
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      User           = "nostr-relay";
      Group          = "nostr-relay";
      StateDirectory = "nostr-rs-relay";          # creates /var/lib/nostr-rs-relay owned by user
      WorkingDirectory = dataDir;                  # relay reads config.toml from here
      ExecStartPre   = "${pkgs.coreutils}/bin/ln -sf ${relayConfig} ${dataDir}/config.toml";
      ExecStart      = "${pkgs.nostr-rs-relay}/bin/nostr-rs-relay";
      Environment    = "RUST_LOG=warn,nostr_rs_relay=info";
      Restart        = "on-failure";
      RestartSec     = "5s";
      NoNewPrivileges = true;
    };
  };
}
