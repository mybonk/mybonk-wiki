{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "bitcoin-container";
  
  # Enable Bitcoin service with Mutinynet configuration
  services.bitcoind = {
    enable = true;
    
    # Mutinynet signet configuration
    extraConfig = ''
      # Enable signet mode (not testnet!)
      signet=1
      
      # Mutinynet-specific signet challenge
      # This identifies which signet network to join
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae
      
      # Connect to Mutinynet infrastructure node
      addnode=45.79.52.207:38333
      
      # Disable DNS seeding (use manual addnode instead)
      dnsseed=0
      
      # 30-second block time 
      # This parameter only works because we're using benthecarman's Mutinynet fork of bitcoin core
      signetblocktime=30
      
      # RPC settings
      rpcuser=nixos
      rpcpassword=workshop3demo
      
      # Network settings
      listen=1
      server=1
      
      # Transaction index
      txindex=1
    '';
    
    # RPC access
    rpc = {
      users = {
        nixos = {
          name = "nixos";
          passwordHMAC = "workshop3demo";
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