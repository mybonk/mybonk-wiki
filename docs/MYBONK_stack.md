# Software Stack

************ THIS IS AN EXAMPLE OF LAYOUT, TO BE UPDATED ***************

Is refered to as a "softawre stack" the group of software bundled together. This eases deployment and allow people to use a solde baseline to trust, build on and contribute to.

MYBONK stack is composed of:

- **GitHub**  [details](https://www.wikipedia.org/wiki/HitHub)
  - Official: https://github.com
  - Description: This is where life is. If you are not using it you are doing really really wrong.
- **Nix/NixOS**
  - Official: https://nixos.org
  - Description: Nix is a tool that takes a unique approach to package management and system configuration. "Reproducible, declarative and reliable systems."
  - Code: https://github.com/NixOS/
- **nix-bitcoin** 
  - Description: [nix-bitcoin](https://nixbitcoin.org/) is a collection of Nix packages and NixOS modules for easily installing
      <strong>full-featured Bitcoin nodes</strong> with an emphasis on <strong>security</strong>. MY₿ONK stack leverages a subset of these [features](https://github.com/fort-nix/nix-bitcoin/#features):

    - **bitcoind**
      - Description: This is bitcoin.
      - Official: https://bitcoin.org/
      - Code: https://github.com/bitcoin/bitcoin
    - **c-lightning**
      - Description: This is Lightning Network (LN)
      - Official:  [https://docs.lightning.engineering/lightning-network-tools/lnd](https://blockstream.com/lightning/)
      - Code: https://github.com/elementsproject/lightning#getting-started
- **nginx**
  - Official: https://nginx.org/
  - Description: Reverse-proxy to route the requests to internal services
  - Code: https://github.com/nginx
- **Tor**
  - Official: https://www.torproject.org/
  - Description: 
  - Code: https://www.torproject.org/download/tor/
- **Wireguard**
  - Official: https://www.wireguard.com/repositories
  - Description: VPN technology built to the core; Client app widely available, allows to connect to your local network remotly using a simple QR code to authenticate.
  - Code: 
- **Hypercore protocol**
  - Official: https://hypercore-protocol.org/
  - Learn more: https://www.ctrl.blog/entry/dht-privacy-discovery-hash.html
  - Code: https://github.com/hypercore-protocol
- **Fedimint**
  - Official: https://fedimint.org/ 
  - Description: 
  - Code: https://github.com/fedimint
- **LNBits**
  - Official: https://lnbits.com
  - Description: This allows for great bitcoin/LN advanced features through APIs and plugins architecture.
  - Code: https://github.com/lnbits/lnbits

