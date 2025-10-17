{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "bitcoin-container";
  
  # Enable Bitcoin service
  services.bitcoind = {
    enable = true;
    
    # Bitcoin Core configuration
    extraConfig = ''
      # Run in testnet mode (for workshop purposes)
      testnet=1
      
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
    bitcoin
    vim
    btop
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  
  services.resolved.enable = true;

  system.stateVersion = "24.11";
}