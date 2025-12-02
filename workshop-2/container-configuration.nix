{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "democont";
  networking.nat.enable = true;
  
  # Enable Bitcoin service
  services.bitcoind = {
    enabled = true;
    testnet = true; # Run in testnet mode (for workshop purposes)

    # Bitcoin Core configuration
    extraConfig = ''
    
      # RPC settings
      rpcuser=nixos
      rpcpassword=workshop2demo
      
      # Network settings
      listen=1
      server=1
      
      # Transaction index (enables full transaction queries)
      txindex=1
    '';
    
    # RPC access
    rpc = {
      users = {
        nixos = {
          name = "nixos";
          passwordHMAC = "workshop2demo";
        };
      };
    };
  };

  # Useful utilities
  environment.systemPackages = with pkgs; [
    bitcoind
    vim
    btop
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  
  services.resolved.enable = true;

  system.stateVersion = "25.11";
}