<p align="center">
<img
    width="320"
    src="img/mybonk_label.png"
    alt="MY₿ONK logo">
</p>
<br/>
<p align="center">
👉 Here are maintained MY₿ONK detailed installation instructions ✍️. 
<br/>
It is very much work in progress. 
<br/>
Anyone can clone and contribute on <a href="https://github.com/mybonk" target="_blank">MY₿ONK's GitHub</a>.
<br/>
Join the conversation on the <a href="https://t.me/mybonk_build" target="_blank">Telegram group</a>!
</p>

---
# Table of Contents
- [0. Before you start](#before-you-start)
  - [Overview](#overview)
  - [Terminology](#terminology)
  - [Advice](#advice)
  - [ssh and auto login](#ssh-and-auto-login)
- [1. Build your MYBONK bitcoin full node](#1-build-your-mybonk-bitcoin-full-node)
    - [1.1 The hardware](#11-the-hardware)
    - [1.2 Download and install NixOS](#12-download-and-install-nixos)
    - [1.3 Download and install MYBONK stack](#13-download-and-install-mybonk-stack)
      - [**Option 1.** The "manually" way](#13-option-1)
      - [**Option 2.** The "automated" way using MYBONK orchestrator](#13-option-2)
  
- [2. Build your MYBONK orchestrator](#2-build-your-mybonk-orchestrator-machine)
    - [2.1. Download and install VirtualBox](#21-download-and-install-virtualbox)
    - [2.2. Build the OS in VirtualBox](#22-build-the-os)
      - [**Option 1.** Using the installation image from Debian](#option-1-using-the-installation-image-from-debian)
      - [**Option 2.** Using a ready-made Virtual Box VDI (Virtual Disk Image)](#option-2-using-a-ready-made-virtual-box-vdi-virtual-disk-image)
    - [2.3. ssh and auto login](#23-ssh-and-auto-login)
    - [2.4. Install Nix](#24-install-nix)
      - [**Option 1.** Using the ready-made binary distribution from nix cache](#option-1-using-the-ready-made-binary-distribution-from-nix-cache)
      - [**Option 2.** Building Nix from the source](#option-2-building-nix-from-the-source)
    - [2.4. Build MYBONK stack](#24-build-mybonk-stack)
    - [2.5. Deploy MYBONK stack to the MYBONK consoles](#25-deploy-mybonk-stack-to-the-mybonk-consoles)
- [3. Basic operations](#3-basic-operations)
    - [3.1. Backup and restore](#31-backup-and-restore)
    - [3.2. Join a Federation](#32-join-a-federation)


# Before you start

![](img/various/console_vs_orchestrator.png)

Read this document from the beginning to the end before getting your hands on the keyboard. Also watch this presentation by Valentin Gagarin about [Flattening the Learning Curve for Nix/NixOS](https://www.youtube.com/watch?v=WFRQvkfPoDI&list=WL&index=87) as Nix/NixOS is the cornerstone of MY₿ONK.

You might have a feeling of "déjà vu" as it is essentially a scrambled from various sources including [nixOS](https://nixos.org) and [nixOS manual](https://nixos.org/manual/nixos/stable/index.html), [nixOS Wiki](https://nixos.wiki/wiki/Main_Page), [nix-bitcoin](https://nixbitcoin.org/), [Virtual Box](https://www.virtualbox.org/), [Raspibolt](https://raspibolt.org/) and [Raspiblitz](https://github.com/rootzoll/raspiblitz#readme) (although the approach of MY₿ONK is radically different). 

If you have any experience with the command line or already run any other full node you have a significant advantage, you could complete this setup in 2 hours maybe, otherwise allocate 1 day.
  
We [collaboratively] take great pride and care maintaining this document so it remains up to date and concise, often it refers to external links. Explore these external links when instructed to, this will make the journey smoother.
  
It is assumed that you know a little bit of everything but not enough so we show you the way step by step based on the typical MY₿ONK setup.

You too can contribute to improving this document on GitHub.
  
Enjoy the ride, no stress, check out our  [baby rabbit holes](/docs/baby-rabbit-holes.md)  :hole: :rabbit2: and the [FAQ](/docs/faq.md) 👷 


### Overview
This example small ecosystem consists of only two elements that we are going to build together:

 
- **One MY₿ONK orchestrator:**
  This machine is used to orchestrate your fleet of MY₿ONK consoles, it is essentially a Linux with a few additional software installed including the Nix package manager.
- **One MY₿ONK console:**
  This machine runs the [MY₿ONK stack](/docs/MYBONK_stack.md) on NixOS. It is setup once and its configuration can be updated remotely using MY₿ONK orchestrator.
  
### Terminology
- '````#````' stands for '````$ sudo````'
- **MY₿ONK core**: Or simply 'MY₿ONK' is a tailor-made full-node [software stack](/docs/MYBONK_stack.md) for MY₿ONK console (although it can run on pretty much any hardware if you are ready to tune and hack a little bit). MY₿ONK core is based on nix-bitcoin itself based on nixOS.
- **MY₿ONK console**: A full-node bitcoin-only hardware platform designed with anonymity, security, low price, performance, durability, low-energy, supply chain resilience and generic parts in mind.
- **MY₿ONK orchestrator**:
  Used to orchestrate your [fleet of] MY₿ONK console[s], it is currently a separate Linux machine with a few additional software installed on including the Nix package manager. The MY₿ONK orchestrator will soon be integrated within the MY₿ONK console but for now it is a separate machine ([ref #30](https://github.com/mybonk/mybonk-core/issues/30#issue-1609334323)).
- **MY₿ONK user**: The end user, you, the family man, the boucher, the baker, the hair dresser, the mechanics... Just want the thing to work, "plug and forget". Uses very simple user interface and never uses the command line. On MAINNET.
- **MY₿ONK operator**: A "MY₿ONK user" that got really serious about it and decided to learn more, move to the next level. Has some "skin in the game" on MAINNET and is happy to experiment on SIGNET. Many operators take part in nodes Federations or create their own Federation.
- **MY₿ONK hacker**: A "MY₿ONK operator" so deep in the rabbit hole, bitcoin, privacy and sovereignty that he became a MY₿ONK hacker. That's an advanced user, student, Maker, researcher, security expert .etc... Just want to tear things apart. Love to use command line. On SIGNET.

### Advice

- **Nix vs. NixOS**: It is *very* important to understand the concept that nix and nixOS are different things: 
  - [Nix](https://nixos.org/manual/nix/stable/) is a purely functional package management and build system. Nix is also the expression language designed specifically for the Nix, it is a pure, lazy, functional language. 
    - Purity means that operations in the language don't have side-effects (for instance, there is no variable assignment).
    - Laziness means that arguments to functions are evaluated only when they are needed.
    - Functional means that functions are “normal” values that can be passed around and manipulated in interesting ways. The language is *not* a full-featured, general purpose language. Its main job is to describe packages, compositions of packages, and the variability within packages.

  - [NixOS](https://nixos.wiki/wiki/Overview_of_the_NixOS_Linux_distribution) is a linux distribution based on Nix. In NixOS, the entire operating system — the kernel, applications, system packages, configuration files, and so on — is built by the Nix package manager.

  [See how Nix and NixOS work and relate](https://nixos.org/guides/how-nix-works.html). For a general introduction to the Nix and NixOS ecosystem, see [nix.dev](https://nix.dev/).

- **Read and explore**: The pros write and read documentation, they are not so much on YouTube. For 1 hour of reading you should spend about 4 hours experimenting with what you learned and so on.

- **Don't trust, verify**: Anything you download on the internet is at risk of being malicious software. Know your sources. Always run the GPG (signature) or SHA-256 (hash) verification (typically next to the download link of an image or package there is a string of hexadecimal characters).

### ssh and auto login

This is so important that we felt it deserved its own section.

It is pre-requisite for the deployment of MY₿ONK, have a look at the section dedicated to ssh in the [baby rabbit holes section](/docs/baby-rabbit-holes.md#ssh) 🕳 🐇

Spare yourself the pain, learn good habits, save tones time and avoid getting locked out of your system by really understanding how ssh works, particularly ssh auto login (auto login *using public and private keys pair* to be specific, it is also significantly more secure than simple password-based login). 

Bellow is an illustration of ssh failed login attempts by bots, hackers, you name it on your machine if you leave password authentication enabled. 

![](img/various/ssh_failed_attempts.gif)

Also learn how to use ```tmux``` and ```tmuxinator``` (checkout the [baby rabbit holes section](/docs/baby-rabbit-holes.md)), it's a bit steep, but this will save you *hours* every week (the ssh session will always be up and running in their respective window panes even after reboot).



---



# 1. Build your MYBONK bitcoin full node
  
  There are many ways to do this, the one detailed here focuses on people with little (but still *some*) technical knowledge.
  
  These steps can and will be automated but for now the goal is for you to *understand* how it works and the mechanics behind it.
  
### 1.1 The hardware

There are many many platforms, physical (HW) or virtual (Virtual Machines, Cloud) to choose from, which is what NixOS was made for in the first place and this is great. A collection of hardware specific platform profiles to optimize settings for different hardware is even being maintained at [NixOS Hardware repository](https://github.com/NixOS/nixos-hardware/blob/master/README.md).


The following steps focus on MY₿ONK console hardware platform only because it would be impossible to maintain and support all the possible combinations for a specific application domain: Each hardware has its own specs, some have additional features (BIOS capabilities, onboard encryption, various kinds of storages and partition systems .etc...) or limitations (too little RAM or unreliable parts, weak power source, "moving parts", cooling issues, higher power consumption .etc...) making it unadvisable to install onto, or too difficult for an average user to setup and maintain; Even little things like bootable or not from USB stick can turn what should be a beautiful journey into hours of frustration tring to just make the thing boot until the next pitfall.

MY₿ONK console is a full-node bitcoin-only hardware platform designed with anonymity, security, low price, performance, durability, low-energy, supply chain resilience and generic parts in mind. You too can get a MY₿ONK console, just join our [Telegram group](https://t.me/mybonk_build).

![](img/various/console_v2_v3.png)


MY₿ONK console can also be used to run Raspiblitz similarly to Raspberry pi or other distributions.

### 1.2 Download and install NixOS

  Now let's install nixOS on MY₿ONK console. 

  A NixOS live CD image can be downloaded from the [NixOS download page](https://nixos.org/download.html#nixos-iso) to install from (make sure you scroll down to the bottom of their home page as the first half of it is about nix *package manager* not nixOS).
  
  Download the "*Graphical* ISO image", it is bigger than the "Minimal ISO image" but it will give you a good first experience using nixOS and will ease some configuration steps like setting up default keyboard layout and disk partitioning which are typical pain points for "not-so-experienced-users". NixOS' new installation wizard in the Graphical ISO image makes it so much more user-friendly.

  Flash the iso image on an USB stick using [balenaEtcher](https://www.balena.io/etcher/).
  
  Plug your MY₿ONK console to the power source and to your network switch using an RJ45 cable.

  Plug-in the screen, the keyboard and the mouse (use a wired mouse to avoid issues, some wireless ones don't work so great and the pointer may jerk around on the screen). These are **used only during this first guided installation procedure**, after this all interactions with the MY₿ONK console will be done "headless" via the MY₿ONK orchestrator as explained in section [Control your MY₿ONK fleet from MY₿ONK orchestrator](#3-basic-operations).

  

  Stick on USB stick in your MY₿ONK console.

  Switch MY₿ONK console on, keep pressing the ``<Delete>`` or ``<ESC>`` key on the keyboard during boot to access the BIOS settings.
  
  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_005.png)


  Make sure the following settings are set in the BIOS:
  
-  ``Boot mode select`` set to ``[Legacy]``
-  ``Boot Option #1`` set to ``USB Device: [USB]``

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_003.png)

  Let your MY₿ONK console boot from the USB stick.

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_010.png)

  After the welcome screen the first thing you are asked to configure is your Location, this is used to make sure the system is configured with the correct language and that the corresponding numbers and date formats are used, just choose the right one for you.

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_020.png)

  The next screen is the keyboard layout selection, which is invariably a point people struggle with depending on what country they are from (azerty, querty ...) and also the variants that exist. **Take your time** trying a few (don't forget to try the special characters '@', '*', '_', '-', '/', ';', ':' .etc... ) until you find the best match. In my case it's "French" variant "French (Macintosh)". Not choosing the correct layout will result in keys inversions which will lead to you not being able to log in your system because the password you think you tap in does not actually enter the correct characters.

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_030.png)
  
  Next you are going to create the users for the system. For now we create a user ```mybonk``` with password ```mybonk``` and we use the same password for the administrator account. 

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_040.png)

  Next you are going to be asked what Desktop you want to have. We don't want a Desktop, select "No desktop". 

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_050.png)

  Confirm "Unfree software" (read the reason behind this mentioned on the screen).
  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_060.png)


  Now we are going to configure the storage devices and partitions. MY₿ONK console has 2 built-in storage devices:
  - ```/dev/sda``` M1 mSATA 128GB SSD used for *system*: This is where the system boots from, where the operating system (and various caches) lives and where the swap space is allocated. 
  - ```/dev/sdb``` SATA 1TB SSD used for *states*: This is where the system settings, the bitcoin blockchain and installed software settings as well as user data is stored. The data on this drive *persisted*.


  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_062.png)

  As this is a fresh new install these drives should not contain any partitions. If there are any on either of the disks delete them by selecting "```New Partition Table```" (creating a new partition table will delete all data on the disk).
  Make sure you select "Master Boot Record (MBR)" instead of GUID Partition Table (GPT) when creating the new partition tables.
  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_065.png)


  Let's configure ```/dev/sda```:
  
  
  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_070.png)

  Let's configure ```/dev/sdb```:
  
  
  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_080.png)


  Now select "Next" to confirm the partitions that are going created (and possibly prior deleted).

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_090.png)


  The installation takes less than one minute click on "Toggle Logs" at the bottom right of the splash screen it to see and understand how the OS is being pulled and installed.

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_100.png)

  "All Done". Do **NOT** Unplug the USB stick just yet.

  Select "Restart now" and click on "Done"

  ![](img/NixOS_install_screenshots/NixOS_install_screenshot_110.png)

  When MY₿ONK console is rebooting remove the USB stick it will then boot on the MBR of /dev/sda. Your system is now running by itself, let's continue its configuration.

  <div id="configuration.nix" ></div>
  After reboot login to MY₿ONK console as ```root``` password ```mybonk```.
  
  ````
  # ls /etc/nixos
  configuration.nix  hardware-configuration.nix
  ````

  ```configuration.nix``` and ```hardware-configuration.nix``` are the files that have been used to build your NixOS.

  - ```configuration.nix```:
    
    The options you selected in the installation wizard have been translated into entries this file. All features and services of the system are configured in this simple, human-readable file (and other ```.nix``` files it might refer to). 

  - ````hardware-configuration.nix````.
  
    This file was auto-generated by the system during setup, you don't normally edit it, make changes to ```configuration.nix``` instead.

  Take some time to have a look at "[Nix - A One Pager](https://github.com/tazjin/nix-1p)" for a first brief introduction to Nix, the language used in these '```.nix```' files. 
  

  Now you want to remotely connect to your MY₿ONK console using ssh. 
  
  We need 2 things: The IP address of your MY₿ONK console and have it run the service ```sshd``` (not running nor installed by default).
  
  
  The IP address has most likely been assigned by your internet router built-in DHCP server. Look for the IP address of any new device in your internet router panel. 

  Alternatively on the terminal with the command ```ip```:

  ````
  $ ip a

  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
  2: enp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 68:1d:ef:2e:0c:b3 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.64/24 brd 192.168.0.255 scope global dynamic noprefixroute enp2s0
       valid_lft 84565sec preferred_lft 84565sec
    inet6 2a02:2788:a4:285:a1fd:5396:bef5:b7c4/64 scope global temporary dynamic 
       valid_lft 301sec preferred_lft 301sec

  ````
  
  Here you can see the wired network interface ```enp2s0``` has the IP address ```192.168.0.64```.

  To avoid having to remember this IP address we can map it to a hostname in our local ```/etc/hosts``` (this is useful to access systems that do not have a DNS entry or if you want to overwrite them in a test or development environment).

  ````
  $ echo "192.168.0.64 mybonk_console" | sudo tee -a /etc/hosts
  ````
  (or just edit the file manually).

  Now let's install, configure and enable ```sshd``` on your MY₿ONK console by tuning the nixOS configuration file:

  ```` 
  # nano /etc/nixos/configuration.nix
  ````
  Add the following lines:

  ````
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };
  ````

  Save the file and exit. 
  
  [```nixos-rebuild```](https://nixos.wiki/wiki/Nixos-rebuild) is the NixOS command used to apply changes made to the system configuration as well as various other tasks related to managing the state of a NixOS system. For a full list of nixos-rebuild sub-commands and options have a look at it man page (````$ man nixos-rebuild````). 

  Build the configuration and activate it, but don't add it (just yet) to the bootloader menu. This is done using the ```test``` subcommand:
  ````
  # sudo nixos-rebuild test
  building Nix...
  building the system configuration...
  activating the configuration...
  setting up /etc...
  reloading user units for root...
  reloading user units for mybonk...
  setting up tmpfiles
  ````
  Check the system logs as the system is reconfiguring:
  ````
  # sudo journalctl -f -n 60
  ````
  Entries referring to the system changes and sshd being enabled are being displayed.

  Confirm it is running:
  ````
  # systemctl status sshd.service 
● sshd.service - SSH Daemon
     Loaded: loaded (/etc/systemd/system/sshd.service; enabled; preset: enabled)
     Active: active (running) since Mon 2023-01-16 16:46:09 CST; 1h 42min ago
   Main PID: 850 (sshd)
         IP: 326.9K in, 379.5K out
         IO: 3.3M read, 0B written
      Tasks: 1 (limit: 9326)
     Memory: 5.9M
        CPU: 336ms
     CGroup: /system.slice/sshd.service
             └─850 "sshd: /nix/store/qy9jighrfllrfy8shipl3j41m9k336vv-openssh-9.1p1/bin/sshd -D -f /etc/ssh/sshd_config [listener] 0 of 10-100 startup>
  ````

  
OK now you're ready, ssh into your MY₿ONK console:

````
$ ssh root@mybonk_console

(root@mybonk_console) Password: 
Last login: Mon Jan 16 06:03:35 2023
#
````

Now that we have seen how easy it is to configure a service let's tune the ```sshd``` service further: Let's disable password-based login and use key-pair only instead. Read some about sshd and [how to setup ssh keys](https://goteleport.com/blog/how-to-set-up-ssh-keys/); once you understand the concept go ahead and adjust sshd configuration in the nixOS configuration again accordingly:

  ```` 
  # nano /etc/nixos/configuration.nix
  ````
  So it looks like this (more details regarding sshd configuration on nixOS can be found on the dedicated [nixOS Wiki page](https://nixos.wiki/wiki/SSH_public_key_authentication)):

  ````
  services.openssh = {
    enable = true;
    #permitRootLogin = "yes";
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNI9e9FtUAuBLAs3Xjcgm78yD6psH+iko+DXOqeEO0VQY+faUKJ0KYF8hp2x8WYtlB7BsrYHVfupwk5YwDSvN36d0KgvYj8hqGRbeKAPynmh5NC1IpX3YU911dNOieDAlGaqFnCicl20FER/bXPfOUCHFm0X7YGudqTU5Zm2TkPKvdH7y+a5mYpZbT2cDKEcRcGbWvUcagw0d0e0jLnXwlTO93WVLpyf5hCmbKFGVpIK1ssx1ij0ZB5rmqlVSscbHY5irt8slXoTOW9go/EpkPD5AWb7RhtTbkA4Vrwk0zqbwoRIIjHF75Z0zK/5oTBVVxEtru96nhXzMII/1D2MTqfD43SK34s7RSklTQjMPlewseDAZtL75MRf1t0eurl1jX9c1gKh9FiGqxTxzIGnfCFIhAISOYD+2m0r9xUaBETOUS1JK3pZc0kqrAStBdah5XjqymNGbKFzaotLuLRab/GdEGA4bjBQ8nnh+0m5AZIHxPvqh3EyRd4eoT8IpQPOE= debian@debian11"
    ]
;
  };
  ````

Play around with the settings and ```nixos-rebuild test``` like earlier, just make sure you don't lock yourself out by disallowing password authentication and forgetting to copy your public key on the console for instance.

Once you have tuned and tested your NixOS configuration enough using ```nixos-rebuild test``` it is time to make it the new default option in the bootloader using the ```switch``` subcommand, making these changes persistent after reboot .
  ````
  # sudo nixos-rebuild switch
  [sudo] password for mybonk: 
  building Nix...
  building the system configuration...
  updating GRUB 2 menu...
  Warning: os-prober will be executed to detect other bootable partitions.
  Its output will be used to detect bootable binaries on them and create new boot entries.
  lsblk: /dev/mapper/no*[0-9]: not a block device
  lsblk: /dev/mapper/raid*[0-9]: not a block device
  lsblk: /dev/mapper/disks*[0-9]: not a block device
  activating the configuration...
  setting up /etc...
  reloading user units for mybonk...
  setting up tmpfiles
  $ 
  ````

You have learned how to:
- Enable a service (````sshd````) and tune it by editing its ```.nix``` configuration file.
- Use ssh with and without password (using key pair).
- Test these configuration changes (e.g. ```nixos-rebuild test```, ```systemctl status sshd```, ```journalctl -f -n 30 -u sshd``` ) before making them persistent across reboots (```nixos-rebuild switch```).

The subsequent sections show how your MY₿ONK console(s) can easily and remotely be fully managed using a MY₿ONK orchestrator. 


*******
### 1.3 Download and install MYBONK stack

*******

<a name="13-option-1"></a>
#### **Option 1.** The "manual" way
**The "manual" way is not the recommanded one, jump to the "automated" way section.**

Exactly the same way we installed, configured and enabled the service openssh modifying only the nixos configuration file ```configuration.nix``` in the previous section, we can enable all sorts of services and parameters. 

```bitcoind``` is readily available in nixpkgs, let's install and run it. 

ssh into MY₿ONK console as '```mybonk```':
`````
$ssh mybonk@mybonk_console
Last login: Tue Jan 17 10:42:32 2023 from 192.168.0.7
[mybonk@mybonkgenesis:~]$ 
`````

Create a new file ```node.nix``` in ```/etc/nixos``` to build a basic bitcoin node with just a few lines...
`````
sudo nano node.nix
`````
And put the following content in it.
````
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services;
  nbLib = config.nix-bitcoin.lib;
  operatorName = config.nix-bitcoin.operator.name;
in {
  imports = [
    ../modules.nix    
  ];

  config =  {
    
    services.bitcoind = {
      enable = true;
      listen = true;
      dbCache = 1000;
    };

  };
}

````

Now edit the main configuration file, ```configuration.nix``` to use ```node.nix``` in the ```imports```:
````
  imports =
    [ 
      ./hardware-configuration.nix
      ./node.nix
    ];

````


<a name="13-option-2"></a>
#### **Option 2.** The "automated" way using a MYBONK orchestrator
  Ref. section [Build your MY₿ONK orchestrator](#build-orchestrator).

---

# 2. Build your MYBONK orchestrator

Note: [Ref #30](https://github.com/mybonk/mybonk-core/issues/30#issue-1609334323) - MY₿ONK orchestrator is planned to be integrated within the MY₿ONK console.

---


This machine is used to orchestrate your [fleet of] MY₿ONK console[s].

You could use your day to day laptop, but some people reported issues or additional pitfalls e.g. on macOS (read-only filesystem / single-user/multi-user vs. Nix package manager). 

To avoid such pitfalls the following steps describe the installation of MY₿ONK orchestrator (Debian + Nix package manager) on a VirtualBox. Ideal in workshops too where everyone has a different machines/OS, let's go!


### 2.1. Download and install VirtualBox
Follow the instructions on their website https://www.virtualbox.org

### 2.2. Build the OS in VirtualBox
  Now that VirtualBox is installed you can have an OS run on it (Linux Debian in our case).
  
  There are 2 ways to do this:
  #### **Option 1.** Using the installation image from Debian
  - From https://www.debian.org/distrib/  
  - With this method you go through the standard steps of installing the Debian OS just as if you were installing it on a new desktop but doing it in a VirtualBox 
  - Don't forget to take note of the the machine's IP address and login details you choose during the installation!
  - Detailed instructions: https://techcolleague.com/how-to-install-debian-on-virtualbox/
  #### **Option 2.** Using a ready-made Virtual Box VDI (Virtual Disk Image)
  - From https://www.linuxvmimages.com/images/debian-11/ 
  - Quicker and more convenient than Option 1 as this is a pre-installed Debian System.
  - Make sure the network setting of its virtual machine is set to "*bridge adapter*". If unsure have a look at [ssh into a VirtualBox](https://www.golinuxcloud.com/ssh-into-virtualbox-vm/#Method-1_SSH_into_VirtualBox_using_Bridged_Network_Adapter).
  - Make sure you generate a new MAC address as shown in the screenshot below before you start the image otherwise if anyone else uses the same image on the network you will get network issues (several machines with same MAC address results in IP addresses conflicts).

    ![](img/various/vm_regenerate_mac_address.png)

  - The login details are typically on the download page (in our case ``debian``/```debian``` and can become ```root``` by using ```$ sudo su -``` ). 
  - What we call hostname is the machine name you can see displayed on on the shell prompt. Because this is a pre-built image make sure you set a hostname different from the default, e.x 'orchestartor_ben', it will avoid confusion when connecting remotely. Changing the hostname is done by running the following command:
    ```
    # hostnamectl set-hostname orchestartor_ben
    ```
    Check the hostname has been updated:
    ```
    $ hostnamectl
    ```
    The shell prompt will reflect the new hostname next time you open a new terminal session.

  - Do not use such images in a production environment. 
  - It is common to have issues with keyboard layout when accessing a machine that has been configured in a different language (e.x. the first few letters of the keyboard write ```qwerty``` instead of ```azerty``` and other keys don't behave normally). There are various ways to adjust this in the configuration but it's out of the scope of this document. The simplest and most effective is to find a way to login using the erroneous keyboard layout anyhow figuring out which key is which then once in the Desktop Environment adjust the settings in "Region & Language" > "Input Source".


Now you need to install some additional pretty common software packages that will be needed to continue. Debian's package manager is [apt](https://www.cyberciti.biz/tips/linux-debian-package-management-cheat-sheet.html?utm_source=Linux_Unix_Command&utm_medium=faq&utm_campaign=nixcmd). Root privileges are required to modify packages installed on the system which is why we prepend the following commands with [sudo](https://www.cyberciti.biz/tips/linux-debian-package-management-cheat-sheet.html?utm_source=Linux_Unix_Command&utm_medium=faq&utm_campaign=nixcmd).

Update the packages index so we are up to date with the latest available ones:

```
$ sudo apt update
```

Install the additional packages (Debian 11 Bullseye) [curl](https://manpages.org/curl), [git](https://manpages.org/git), ***[gnupg2](), [dirmngr]()***:
```
$ sudo apt -y install curl git
```

### 2.3. ssh and auto login

Note that in Debian ssh restrictions apply to ```root``` user: 

In the ssh server configuration '```/etc/ssh/sshd_config```'

Open the ssh server configuration ```/etc/ssh/sshd_config``` using ```nano /etc/ssh/sshd_config``` and see the setting ```PermitRootLogin```, its value can be ```yes```, ```prohibit-password```, ```without-password```. The later two ban all interactive authentication methods, allowing only public-key, hostbased and GSSAPI authentication.

It is generally advised to avoid using user ```root``` especially to remote-access. You can use ```sudo -i``` from another user instead when needed so just leave the setting ```PermitRootLogin``` as ```prohibit-password```.


### 2.4. Install Nix
  
  
  #### **Option 1.** Using the ready-made binary distribution from nix cache
  - Quicker and more convenient than Option 2 as it has been pre-built for you.

    ssh into the orchestrator and run:
    ``` 
    $ sh <(curl -L https://nixos.org/nix/install)   
    ```

  You can see outputs related to Nix binary being downloaded and installed. 

  
  Installation almost finished: To ensure that the necessary environment variables are set, as instructed, run the following command to 'source' the file:

  ```
  . ~/.nix-profile/etc/profile.d/nix.sh
  ```
      
  Check the installation went OK

  ```
  $ nix --version
  nix (Nix) 2.12.0
  ```

  Have a look at the nix man page to familiarize yourself with it and all its sub-commands.
  ```
  $ man nix
  ```
  

  #### **Option 2.** Building Nix from the source
  - Regarded as the "sovereign" way to do it but takes more time.
  - Follow the instructions on nix page https://nixos.org/nix/manual/#ch-installing-source
  

### 2.4. Build MYBONK stack
Now that your MY₿ONK orchestrator is up and running we can use it to build MY₿ONK stack and deploy it seamlessly to the [fleet of] MY₿ONK console(s) in a secure, controlled and effortless way.

[MY₿ONK stack](/docs/MYBONK_stack.md) is derived from [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin/). Have a look at their GitHub, especially their [examples](https://github.com/fort-nix/nix-bitcoin/blob/master/examples/README.md) section.

Login to your MY₿ONK orchestrator (make sure that the virtual machine hosting it as described in section '[2. Build your MYBONK orchestrator](#2-build-your-mybonk-orchestrator-machine)' is actually running):


```
ssh debian@mybonk_orchestrator
$
```

Setup passwordless ssh access for user ```root``` to connect from from your MY₿ONK orchestrator to the MY₿ONK console (have a look at the section dedicated to ssh in the [baby rabbit holes](/docs/baby-rabbit-holes.md#ssh) if needed).

And add a shortcut for it in your ssh config file (```~/.ssh/config```): 


```
Host mybonk-console-root
    Hostname 192.168.0.64
    User root
    PubkeyAuthentication yes
    IdentityFile ~/.ssh/id_rsa
    AddKeysToAgent yes

```

Now, test that you can ssh without password from your MY₿ONK orchestrator to your MY₿ONK console (using the shortcut ```mybonk-console-root``` we just created:

```
$ ssh mybonk-console-root
Last login: Fri Mar  3 13:27:34 2023 from 192.168.0.64
# 

```

All good, now logout from your MY₿ONK console to get back to your MY₿ONK orchestrator terminal.

MY₿ONK core is based on nix-bitcoin on top of which MY₿ONK specificities are overlayed.

Start by cloning nix-bitcoin project repository in your MY₿ONK orchestrator home directory:

```
cd 
git clone https://github.com/fort-nix/nix-bitcoin
```


```
cd nix-bitcoin
ls -la

total 88
drwxr-xr-x  9 debian debian 4096 Jan 11 17:58 .
drwxr-xr-x 18 debian debian 4096 Jan 11 17:58 ..
-rw-r--r--  1 debian debian 1371 Jan 11 17:58 .cirrus.yml
drwxr-xr-x  8 debian debian 4096 Jan 11 17:58 .git
-rw-r--r--  1 debian debian 1079 Jan 11 17:58 LICENSE
-rw-r--r--  1 debian debian 8653 Jan 11 17:58 README.md
-rw-r--r--  1 debian debian 7128 Jan 11 17:58 SECURITY.md
-rw-r--r--  1 debian debian   65 Jan 11 17:58 default.nix
drwxr-xr-x  3 debian debian 4096 Jan 11 17:58 docs
drwxr-xr-x  6 debian debian 4096 Jan 11 17:58 examples
-rw-r--r--  1 debian debian 2144 Jan 11 17:58 flake.lock
-rw-r--r--  1 debian debian 4121 Jan 11 17:58 flake.nix
drwxr-xr-x  2 debian debian 4096 Jan 11 17:58 helper
drwxr-xr-x  6 debian debian 4096 Jan 11 17:58 modules
-rw-r--r--  1 debian debian   45 Jan 11 17:58 overlay.nix
drwxr-xr-x 16 debian debian 4096 Jan 11 17:58 pkgs
-rw-r--r--  1 debian debian  234 Jan 11 17:58 shell.nix
drwxr-xr-x  5 debian debian 4096 Jan 11 17:58 test
```

The directory ```examples``` contains the basic elements on top of which we are going to overlay MY₿ONK specificities and features. Don't worry too much trying to figure out what each of these files and directories do, we are only going to copy/past those we need, adjust them and explain what we do.


Get into the ```example``` directory and run the command ```nix-shell```. It is very important you do this as [nix-shell](https://nixos.org/manual/nix/stable/command-ref/nix-shell.html) (interprets ```shell.nix```) pulls all the dependencies and gives you access to the exact versions of the specified packages.

```
cd examples
nix-shell
```

It will take a few minutes to execute and start showing output on the terminal, be patient.

Once complete you will be greeted by a nix-bitcoin splash and the nix-shell prompt:
```
       _           _     _ _            _       
 _ __ (_)_  __    | |__ (_) |_ ___ ___ (_)_ __  
| '_ \| \ \/ /____| '_ \| | __/ __/ _ \| | '_ \ 
| | | | |>  <_____| |_) | | || (_| (_) | | | | |
|_| |_|_/_/\_\    |_.__/|_|\__\___\___/|_|_| |_|
                                                
Enter "h" or "help" for documentation.

[nix-shell:~/nix-bitcoin/examples]$
```

As instructed enter "h" to see the help page describing the commands nix-bitcoin team made available to facilitate the configuration/build/deploy process.

Now go back to your home directory and create a new directory ```mybonk``` in which we will construct MY₿ONK stack then deploy to the MY₿ONK console from.

```
cd
mkdir mybonk
cd mybonk
```

Copy the initial files and directory ```nix-bitcoin-release.nix```, ```configuration.nix```, ```shell.nix```, ```krops``` and ```.gitignore``` from ```nix-bitcoin/examples```.

````
cp -r ../nix-bitcoin/examples/{nix-bitcoin-release.nix,configuration.nix,shell.nix,krops,.gitignore} .
````

Let's look at what we have:
````
debian@debian11:~/mybonk$ ls -la
total 36
drwxr-xr-x  3 debian debian  4096 Jan 11 17:58 .
drwxr-xr-x 18 debian debian  4096 Jan 11 17:58 ..
-rw-r--r--  1 debian debian     9 Jan 11 17:58 .gitignore
-rw-r--r--  1 debian debian 12149 Jan 11 17:58 configuration.nix
drwxr-xr-x  2 debian debian  4096 Jan 11 17:58 krops
-rw-r--r--  1 debian debian     5 Jan 11 17:58 nix-bitcoin-release.nix
-rw-r--r--  1 debian debian   260 Jan 11 17:58 shell.nix
````

- ```configuration.nix```: Explained in a <a href="#configuration.nix">previous session</a>.
- ```krops```: Directory used for deployment (described in section [#2.5 Deploy MY₿ONK stack to the MY₿ONK consoles](#25-deploy-mybonk-stack-to-the-mybonk-consoles))
- ```shell.nix```: The nix-shell file as seen a bit earlier.
- ```nix-bitcoin-release.nix```: Hydra jobset declaration




  

### 2.5. Deploy MYBONK stack to the MYBONK consoles
  
There are dozens of options available to deploy a nixOS configuration: NixOps, krops, morph, NixUS, deploy-rs, Bento .etc.. , each with their pros and cons.
[NixOps](https://github.com/NixOS/nixops/blob/master/README.md), the official DevOps tool of NixOS is nice but it has some flaws. [krops](https://github.com/krebs/krops/blob/master/README.md) solves some of these flaws with very simple concepts, some of its features are:
- store your secrets in password store
- build your systems remotely
- minimal overhead (it's basically just nixos-rebuild switch!)
- run from custom nixpkgs branch/checkout/fork

We are going to use krops too as it is already used by nix-bitcoin. 

Read [this very well written article](https://tech.ingolf-wagner.de/nixos/krops/) to get an idea of how krops works before you get started.

First, krops needs to ssh MY₿ONK console using automatic login with keys pair. We have done this earlier let's move on ...

On your orchestrator machine make sure you are in the (```mybonk```) deployment directory, edit ```krops/deploy.nix```` which is the main deployment configuration file:

Locate the FIXME and set the target to the name of the ssh config entry created earlier, i.e. mybonk-node.

```

```



# 3. Basic operations

This is when the tool 'tmuxinator' comes along. 

Have a look at the tmuxinator section in the [baby rabbit holes](/docs/baby-rabbit-holes.md).

For your convenience, in the scope of [MY₿ONK](https://github.com/mybonk/mybonk-core/blob/main/docs/INSTALLATION.md), you can reuse the tmuxinator template in the root of the Git repository [.tmuxinator.yml](/.tmuxinator_console.yml).


### 3.1. Backup and restore

### 3.2. Join a Federation



