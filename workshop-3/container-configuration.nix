{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "nginx-container";

  # Enable nginx web server
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      root = "/var/www";
      locations."/" = {
        index = "index.html";
      };
    };
  };

  # Create a simple web page
  system.activationScripts.setupWebRoot = ''
    mkdir -p /var/www
    cat > /var/www/index.html <<EOF
    <!DOCTYPE html>
    <html>
    <head><title>NixOS nginx Test</title></head>
    <body>
      <h1>Welcome to nginx on NixOS!</h1>
      <p>This is running nginx version: NGINX_VERSION</p>
      <p>Workshop 3: Package version override demo</p>
    </body>
    </html>
    EOF

    # Replace NGINX_VERSION with actual version
    ${pkgs.gnused}/bin/sed -i "s/NGINX_VERSION/$(${pkgs.nginx}/bin/nginx -v 2>&1 | cut -d'/' -f2)/" /var/www/index.html
  '';

  # Useful utilities
  environment.systemPackages = with pkgs; [
    nginx
    curl
    vim
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  services.resolved.enable = true;

  # Open firewall for nginx
  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "24.11";
}
