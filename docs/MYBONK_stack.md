# MY₿ONK stack

Is referred to as a "MY₿ONK stack" the group of software bundled together to ease deployment and allow people to use a solid baseline to trust, build on, benefit from and contribute to.

The MY₿ONK stack we are working on is composed of:

- **GitHub**  [details](https://www.wikipedia.org/wiki/HitHub)
  - Official: https://github.com
  - Description: This is where life is. If you are not using it you are doing really really wrong.
- **Nix/NixOS**
  - Official: https://nixos.org
  - Description: Nix is a tool that takes a unique approach to package management and system configuration. "Reproducible, declarative and reliable systems."
  - Source:  https://github.com/NixOS/
- **nix-bitcoin** 
  - Description: [nix-bitcoin](https://nixbitcoin.org/) is a collection of Nix packages and NixOS modules for easily installing
      <strong>full-featured Bitcoin nodes</strong> with an emphasis on <strong>security</strong>. MY₿ONK stack leverages a subset of these [features](https://github.com/fort-nix/nix-bitcoin/#features):

    - **bitcoind**
      - Description: This is bitcoin.
      - Official: https://bitcoin.org/
      - Source:  https://github.com/bitcoin/bitcoin
    - **Fulcrum**
      - Description: Bitcoin address index.
      - Motivation in choice: https://sparrowwallet.com/docs/server-performance.html 
      - In simple terms, you provide it an arbitrary address, and it returns transactions associated with that address. It is not Bitcoin reference implementation's role to support this functionality so Fulcrum (a.k.a "Electrum server") provides it. 
      - There are other implementations available of "Electrum servers" such as the original Electrum server (deprecated in 2017), ElectrumX (public server in mind), Electrs (personal use in mind),  Electrs-esplora (massive data requirements) ...
      - Fulcrum is a recent implementation written in modern C++. It has higher disk space requirements than ElectrumX and Electrs (32GB, 75GB respectively and 1TB for Fulcrum) but the performance it achieves once the index is built (2-3 days) simply remarkable.
      - Fulcrum is the Electrum server selected to run on MY₿ONK stack.
    - **C-lightning**
      - Description: This is Lightning Network (LN)
      - Official:  [https://docs.lightning.engineering/lightning-network-tools/lnd](https://blockstream.com/lightning/)
      - Source:  https://github.com/cculianu/Fulcrum
- **nginx**
  - Official: https://nginx.org/
  - Description: Reverse-proxy to route the requests to internal services
  - Source:  https://github.com/nginx
- **Tor**
  - Official: https://www.torproject.org/
  - Description: 
  - Source:  https://www.torproject.org/download/tor/
- **Tailscale**
  - Official: https://www.wireguard.com/repositories
  - Description: Allows to connect to your local network remotely with "zero configuration".
  - Source:  

- **Fedimint**
  - Official: https://fedimint.org/ 
  - Description: 
  - Source:  https://github.com/fedimint ([dev doc and installation](https://github.com/fedimint/fedimint/blob/master/docs/dev-running.md))

- **LNBits**
  - Official: https://lnbits.com
  - Description: This allows for great bitcoin/LN advanced features through APIs and plugins architecture.
  - Source:  https://github.com/lnbits/lnbits

- **XMPP**
  - Official: https://xmpp.org/
  - Learn more: 
  - Source:  

- **Prosŏdy**
  - Official: https://prosody.im/
  - Learn more: 
  - Source:  

- **Hypercore protocol**
  - Official: https://hypercore-protocol.org/
  - Learn more: https://www.ctrl.blog/entry/dht-privacy-discovery-hash.html
  - Source:  https://github.com/hypercore-protocol
  
