# Tmux and Tmuxinator configuration module
# Deploys tmux/tmuxinator and their dotfiles to operator user's home directory

{ config, pkgs, lib, ... }:

{
  # Install tmux and tmuxinator packages
  environment.systemPackages = with pkgs; [
    btop
    tmux
    tmuxinator
  ];

  # Deploy dotfiles using a systemd service that runs after user creation
  systemd.services.deploy-operator-dotfiles = {
    description = "Deploy tmux/tmuxinator dotfiles to operator home";
    wantedBy = [ "multi-user.target" ];
    after = [ "users.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Copy dotfiles
      cp ${../dotfiles/.bash_history} /home/operator/.bash_history
      cp ${../dotfiles/.tmux.conf} /home/operator/.tmux.conf
      cp ${../dotfiles/.tmuxinator.yml} /home/operator/.tmuxinator.yml
      cp ${../dotfiles/.bash_aliases} /home/operator/.bash_aliases

      # Set correct ownership and permissions
      chown -R operator:users /home/operator/.bash_history
      chown -R operator:users /home/operator/.tmux.conf
      chown -R operator:users /home/operator/.tmuxinator.yml
      chown -R operator:users /home/operator/.bash_aliases
      chmod 644 /home/operator/.bash_history
      chmod 644 /home/operator/.tmux.conf
      chmod 644 /home/operator/.tmuxinator.yml
      chmod 644 /home/operator/.bash_aliases
    '';
  };
}
