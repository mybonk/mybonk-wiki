{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "demo-container";
  
  # Generate secrets automatically (for development/workshop purposes)
  # In production, manage secrets manually in /etc/nix-bitcoin-secrets
  nix-bitcoin.generateSecrets = true;
  
  # Enable Bitcoin Core
  services.bitcoind = {
    enable = true;
    
    # Use signet for workshop (faster sync, free test coins)
    extraConfig = ''
      # Signet configuration (default signet)
      signet=1
      
      # RPC settings
      server=1
      
      # Index transactions (required for electrs)
      txindex=1
      
      # Reduce memory usage for workshop/demo
      dbcache=450
      maxmempool=300
    '';
  };
  
  # Enable Electrs (Electrum server)
  services.electrs = {
    enable = true;
    # electrs will automatically connect to bitcoind
    # and serve on default port 50001
  };
  
  # Enable c-lightning (Lightning Network daemon)
  services.clightning = {
    enable = true;
    # c-lightning automatically integrates with bitcoind
  };
  
  # Enable RTL (Ride The Lightning web interface)
  services.rtl = {
    enable = true;
    
    # Enable c-lightning node in RTL
    nodes.clightning.enable = true;
    
    # Configure network access
    address = "0.0.0.0";  # Listen on all interfaces (for container access)
    port = 3000;
  };
  
  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";  # WORKSHOP ONLY - NEVER use in production!
  };
  
  # Add your SSH public key here (recommended over password authentication)
  # Replace with your actual key from ~/.ssh/id_ed25519.pub or similar
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
  ];
  
  # Enable the nix-bitcoin operator user for easy CLI access
  nix-bitcoin.operator = {
    enable = true;
    name = "operator";
  };
  
  # Create the operator user
  users.users.operator = {
    isNormalUser = true;
    # In production, use hashedPassword or passwordFile instead of plaintext
    password = "workshop4";
    
    # You can also add SSH keys for the operator user
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
    ];
  };
  
  # Useful utilities for the workshop
  environment.systemPackages = with pkgs; [
    vim
    btop
    curl
  ];
  
  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  services.resolved.enable = true;
  
  # Open firewall for services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      3000  # RTL web interface
    ];
  };

  system.stateVersion = "24.11";
}
