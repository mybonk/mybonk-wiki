# host-shell.nix — include this in your HOST machine's NixOS configuration.
#
# Wraps the system rsync with a two-line progress display:
#   line 1 — current file being transferred (updates in place)
#   line 2 — overall progress, transfer rate, ETA / TOTAL on completion
#
# The wrapper is transparent: it accepts every flag rsync accepts.
# It injects --no-inc-recursive and --info=progress2,name1 automatically,
# so drop -v and --progress from any rsync calls — the wrapper replaces them.
#
# The TTY guard ensures that scripts calling rsync non-interactively
# (e.g. cron jobs, pipe chains) are completely unaffected.
#
# Include in your host's /etc/nixos/configuration.nix:
#
#   imports = [ /path/to/workshop-19/host-shell.nix ];
#
# then rebuild: sudo nixos-rebuild switch

{ ... }:

{
  programs.bash.interactiveShellInit = ''
    rsync() {
      if [ -t 1 ]; then
        command rsync --no-inc-recursive --info=progress2,name1 "$@" 2>&1 | \
          stdbuf -oL tr '\r' '\n' | \
          awk '
            BEGIN { printf "\n\n" }
            NF == 0 { next }
            $2 ~ /%/ {
              if (!start) start = systime()
              last    = $0
              pct     = $2 + 0
              elapsed = systime() - start
              if (pct > 0 && elapsed > 0) {
                rem = int(elapsed * (100 - pct) / pct)
                eta = sprintf("%dh%02dm%02ds", rem/3600, (rem%3600)/60, rem%60)
              } else {
                eta = "--"
              }
              printf "\033[1A\r\033[2K%s  ETA %-12s\033[0K\033[1B\r", $0, eta
              fflush()
            }
            !($2 ~ /%/) {
              printf "\033[2A\r\033[2K%.100s\033[0K\033[2B\r", $0
              fflush()
            }
            END {
              if (last) {
                total = systime() - start
                tot   = sprintf("%dh%02dm%02ds", total/3600, (total%3600)/60, total%60)
                printf "\033[1A\r\033[2K%s  TOTAL %-12s\033[0K\033[1B\r\n",
                  gensub(/[0-9]+%/, "100%", 1, last), tot
                fflush()
              }
            }
          '
        return ''${PIPESTATUS[0]}
      else
        command rsync "$@"
      fi
    }
  '';
}
