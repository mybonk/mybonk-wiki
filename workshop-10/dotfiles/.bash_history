history
journalctl -u sshd.service
journalctl -u systemd-tmpfiles-setup.service
journalctl -f -n 100 
systemctl --type=service --state=running
systemctl --type=service --state=dead
systemctl --type=service --state=exited
systemctl --type=service --state=failed
systemctl --type=service --state=inactive
ssh -o "StrictHostKeyChecking no" operator@host
ssh-keygen -R host
systemctl cat sshd
tmuxinator
tmux list-sessions
tmux detach-client
tmux attach-session
tmux kill-server
tmux kill-session
journalctl -f -n 40 -u sshd*
systemctl show bitcoind sshd
ping -c 3 bitcoin
ping -c 3 lightning
ping -c 3 8.8.8.8
nix build .#packages.x86_64-linux.bitcoin-vm
sudo ./run-bitcoin-vm.sh
sudo ./stop-bitcoin-vm.sh
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getblockchaininfo
lsblk
df -h /var/lib/bitcoind
qemu-img info vm-data/bitcoin-vm.qcow2
ps aux | grep qemu
cat /var/run/bitcoin-vm.pid
nslookup bitcoin
cat /var/lib/dnsmasq/dnsmasq.leases | grep bitcoin
ss -tlnp | grep 38332
sudo nixos-container create lightning --flake .#lightning
sudo nixos-container start lightning
sudo nixos-container run lightning -- lightning-cli --network=signet getinfo
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getpeerinfo
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getblockchaininfo | grep chain
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getblockchaininfo
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getnewaddress
bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getbalance
curl -s --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://bitcoin:38332/
curl -s --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://lightning:38332/
sudo nixos-container root-login lightning
lightning-cli --network=signet getinfo
lightning-cli --network=signet newaddr
lightning-cli --network=signet listfunds
sudo nixos-container run lightning -- lightning-cli --network=signet getinfo
ip addr show eth0
cat /var/lib/dnsmasq/dnsmasq.leases | grep bitcoin
sudo nixos-container show-ip lightning
sudo nixos-container list
sudo nixos-container run lightning -- ping -c 3 bitcoin
systemctl status firewalld
sudo nixos-container run lightning -- nslookup bitcoin
sudo nixos-container run lightning -- journalctl -u clightning.service -n 50
sudo nixos-container run lightning -- ping -c 3 bitcoin
sudo nixos-container run lightning -- nslookup bitcoin
sudo nixos-container destroy lightning
sudo nixos-container destroy tlightning
sudo nixos-container list
for c in $(sudo nixos-container list); do sudo nixos-container destroy $c; done
rm -rf vm-data/
watch 'du -ac -d0 /var/lib/bitcoind'
watch -n 2 'bitcoin-cli -getinfo | grep progress'
watch 'sudo du -ach -d0 /var/lib/bitcoind'
watch 'sudo du -ac -d0 /var/lib/bitcoind'
sudo machinectl terminate lightning
sudo nixos-container destroy lightning
sudo nixos-container root-login lightning
ls -la /home/operator/