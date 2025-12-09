# Tmux and Tmuxinator configuration module
# Deploys tmux/tmuxinator and their dotfiles to operator user's home directory

{ config, pkgs, lib, ... }:

{
  # Install tmux and tmuxinator packages
  environment.systemPackages = with pkgs; [
    tmux
    tmuxinator
  ];

  # Deploy dotfiles to operator's home directory
  systemd.tmpfiles.rules = [
    # Deploy .tmux.conf
    "f /home/operator/.tmux.conf 0644 operator operator - ${../dotfiles/.tmux.conf}"

    # Create .tmuxinator directory
    "d /home/operator/.tmuxinator 0755 operator operator -"

    # Deploy .tmuxinator.yml (default config)
    "f /home/operator/.tmuxinator.yml 0644 operator operator - ${../dotfiles/.tmuxinator.yml}"

    # Deploy tmuxinator.yml (workshop layout)
    "f /home/operator/.tmuxinator/tmuxinator.yml 0644 operator operator - ${../dotfiles/tmuxinator.yml}"
  ];
}
