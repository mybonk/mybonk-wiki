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
journalctl -xeu container@lightning.service
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
sudo bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getblockchaininfo
lsblk
df -h /var/lib/bitcoind
qemu-img info vm-data/bitcoin-vm.qcow2
ps aux | grep qemu
cat /var/run/bitcoin-vm.pid
nslookup bitcoin
cat /var/lib/dnsmasq/dnsmasq.leases | grep bitcoin
systemctl status clightning --no-pager
ss -tlnp 
ss -tlnp | grep 38332
ss -tlnp | grep 9735
sudo nixos-container create lightning --flake .#lightning
sudo nixos-container start lightning
sudo lightning-cli getinfo
sudo bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getpeerinfo
sudo bitcoin-cli -signet getnetworkinfo |jq .
sudo bitcoin-cli -signet getblockchaininfo |jq .
sudo bitcoin-cli -signet getblockchaininfo | grep chain
sudo bitcoin-cli -signet getblockchaininfo | jq '{ chain: .chain, blocks: .blocks, headers: .headers, verificationprogress: .verificationprogress, initialblockdownload: .initialblockdownload }'
sudo bitcoin-cli -signet getnewaddress
sudo bitcoin-cli -signet getbalance
sudo bitcoin-cli -signet getconnectioncount
sudo bitcoin-cli -signet addnode "192.168.0.6:38333" "add"
sudo bitcoin-cli -signet connect "lightning"
sudo bitcoin-cli -signet connect "192.168.0.6:38333"
sudo bitcoin-cli -signet getbestblockhash
sudo bitcoin-cli -signet getblockcount
sudo bitcoin-cli -signet getaddednodeinfo bitcoin
curl -s --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://bitcoin:38332/
curl -s --user bitcoin:bitcoin --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://lightning:38332/
sudo nixos-container root-login lightning
sudo lightning-cli getinfo
sudo lightning-cli newaddr
sudo lightning-cli listfunds
sudo lightning-cli getinfo
ip addr show eth0
cat /var/lib/dnsmasq/dnsmasq.leases | grep bitcoin
sudo systemctl reset-failed container@lightning.service
sudo nixos-container show-ip lightning
sudo nixos-container list
sudo ping -c 3 bitcoin
systemctl status firewalld
sudo nslookup bitcoin
sudo journalctl -u clightning.service -n 50
sudo ping -c 3 bitcoin
sudo nslookup bitcoin
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
sudo systemctl stop container@lightning.service
sudo systemctl reset-failed container@lightning.service
sudo ip link delete vb-lightning
sudo bitcoin-cli -signet getblockchaininfo
sudo bitcoin-cli -signet createwallet testwallet
bitcoin-cli -signet loadwallet testwallet
sudo bitcoin-cli -signet getnewaddress
sudo systemctl status bitcoind
sudo systemctl status clightning
sudo lightning-cli getinfo
sudo bitcoin-cli -signet getpeerinfo
sudo bitcoin-cli -signet getpeerinfo | jq -r '.[] | "Address: \(.addr)\nAgent: \(.subver)\nVersion: \(.version)\n---"'
sudo bitcoin-cli -signet getblockchaininfo | jq -r
sudo bitcoin-cli -signet createwallet test
sudo bitcoin-cli -signet getnewaddress
watch 'sudo du -ac -d0 /var/lib/bitcoind'
watch 'sudo du -ac -d2 /var/lib/bitcoind'
find . -name "*term*"
tailscale status
sudo du -h -d 0 /var/lib/bitcoind/signet/{blocks,indexes,chainstate}
watch sudo du -h -d 0 /var/lib/bitcoind/signet/{blocks,indexes,chainstate}
sudo ls -la /var/lib/bitcoind/signet/{chainstate,indexes,blocks}
sudo rsync -avz --partial --inplace --append --stats --exclude '*/*.lock' root@bitcoin:/var/lib/bitcoind/signet/{blocks,chainstate,indexes} /var/lib/nixos-containers/lightning/var/lib/bitcoind/signet
sudo systemctl stop bitcoind
sudo systemctl stop clightning
sudo systemctl stop mempool
sudo systemctl stop electrs
sudo systemctl stop rtl
sudo systemctl start bitcoind
sudo systemctl start clightning
sudo systemctl start mempool
sudo systemctl start electrs
sudo systemctl start rtl
sudo systemctl stop rtl
sudo systemctl restart bitcoind
sudo systemctl restart clightning
sudo systemctl restart mempool
sudo systemctl restart electrs
sudo systemctl restart rtl
systemctl status bitcoin-rpc-redirect.service
systemctl start bitcoin-rpc-redirect.service
systemctl stop bitcoin-rpc-redirect.service
sudo lightning-cli getinfo | jq -r '.id'
sudo lightning-cli connect 036ff0237dc11493cea1f5e521e62c99b80fdb088c4f4f1d69c84b1f297f055481@lightning2:9735
sudo lightning-cli listfunds
sudo lightning-cli listpeers
sudo lightning-cli fundchannel 036ff0237dc11493cea1f5e521e62c99b80fdb088c4f4f1d69c84b1f297f055481 1000
systemctl status bitcoin-rpc-redirect.service
systemctl stop bitcoin-rpc-redirect.service
systemctl start bitcoin-rpc-redirect.
ss -tlnp | grep 9735
sudo iptables -L INPUT -n
sudo iptables -L nixos-fw -n
pgrep -a qemu
sudo pkill -f "qemu.*bitcoin"
sudo pkill -9 -f "qemu.*bitcoin"
sudo pkill -f "qemu.*"
sudo pkill -9 -f "qemu.*"
sudo kill $(cat /var/run/bitcoin-vm.pid)
cat /var/run/bitcoin-vm.pid
sudo lightning-cli connect 02afc70c836874cb8e91c6b5f6ac41ba2fd484238efa2e934c6674f2ea60c72b99@lightning:9735
sudo lightning-cli connect 03d23af0a8a89a4243c2ad76c2561fc3d1310fd71d4cf51997f4f2e68862fcd23e@lightning2:9735
sudo lightning-cli listfunds
sudo lightning-cli listpeers
sudo lightning-cli fundchannel 02afc70c836874cb8e91c6b5f6ac41ba2fd484238efa2e934c6674f2ea60c72b99 1000
sudo lightning-cli fundchannel 03d23af0a8a89a4243c2ad76c2561fc3d1310fd71d4cf51997f4f2e68862fcd23e 1000
sudo lightning-cli bkpr-listbalances
sudo lightning-cli listfunds | jq '[.channels[].our_amount_msat] | add / 1000'
sudo lightning-cli listfunds | jq '[.outputs[].amount_msat] | add / 1000'
sudo lightning-cli getinfo | jq '.fees_collected_msat / 1000'
sudo lightning-cli listforwards | jq '.forwards[-100000:] | map(.status) | reduce .[] as $status ({}; .[$status] = (.[$status] // 0) + 1)'
sudo lightning-cli listforwards | jq '.forwards[-10000:] | map(.status) | reduce .[] as $status ({}; .[$status] = (.[$status] // 0) + 1)'

