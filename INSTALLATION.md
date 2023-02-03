<p align="center">
<img
    width="320"
    src="docs/img/mybonk_label.png"
    alt="MY₿ONK logo">
</p>
<br/>

!!!!! this is work in progress, will be actualized during next hackaton !!!!!!


---
# Table of Contents

- [Table of Contents](#table-of-contents)
- [Foreword](#foreword)
- [Terminology](#terminology)
- [Overview](#overview)
- [Advice](#advice)
- [0. ssh and auto login](#0-ssh-and-auto-login)
- [1. Build your MYBONK bitcoin full node](#1-build-your-mybonk-bitcoin-full-node)
    - [1.1 The hardware](#11-the-hardware)
    - [1.2 Download and install NixOS](#12-download-and-install-nixos)
    - [1.3 Download and install MYBONK](#13-download-and-install-mybonk)
      - [**Option 1.** The way it is done "manually""](#13-option-1)
      - [**Option 2.** The way it is automated using a MYBONK orchestration machine](#13-option-2)
  
- [2. Build your MYBONK orchestration machine](#2-build-your-mybonk-orchestration-machine)
    - [2.1. Download and install VirtualBox](#21-download-and-install-virtualbox)
    - [2.2. Build the OS](#22-build-the-os)
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


# Foreword

What is commonly refered to as "*bitcoin full node distribution*" or simply "*full node*" is a set of software put together in such a way that it makes the experience of installing it and operating it as smooth and secure as possible.


Most full node distributions are great to experiment and learn and break things. 

Like most bitcoin full node distributions MY₿ONK can run on a variety of hardware or virtual machines and run various additional software, which we encourage. However we focus on bitcoin-only stripped stack refered to as the "(MY₿ONK stack)[MYBONK_STACK.md]" or simply MY₿ONK, it would be impossible to keep up with all the various more or less usable hardware one can find on the market and the variety of more or less reliable software one can find on the internet. 


Read this document from the beginning to the end once, then read it again before you decide to get your hands dirty. 

You might have a feeling of "déjà vu" as it is essentially a scrambled from various sources including [nixOS](https://nixos.org) and [nixOS manual](https://nixos.org/manual/nixos/stable/index.html), [nixOS Wiki](https://nixos.wiki/wiki/Main_Page), [nix-bitcoin](https://nixbitcoin.org/), [Virtual Box](https://www.virtualbox.org/), [raspibolt](https://raspibolt.org/) and [Raspiblitz](https://github.com/rootzoll/raspiblitz#readme) (although the approach of MY₿ONK is radically different). 

If you have any experience with the command line or already run any other full node you have a significant advantage, you could complete this setup in 2 hours maybe, otherwize allocate 1 day.
  
We [collaboratively] take great pride and care maintaining this document so it remains clear and concise, often it references external links. Explore them when instructed to, this will make the journey smoother even pleasant.
  
It is assumed that you know a little bit of everything but not enough so we show you the way step by step based on the typical MY₿ONK setup.
You too can contribute to impriving this document on GitHub.
  
Enjoy the ride, no stress, Check out our [FAQ](FAQ.md) and the [things that really make a difference](BABY-RABBIT-HOLES.md)  :hole: :rabbit2:

# Terminology
- **MY₿ONK core**: Or simply 'MY₿ONK' is a tailor-made full-node software stack for MY₿ONK console (although it can run on pretty much any hardware if you are ready to tune and hack a little bit). MY₿ONK core is based on nix-bitcoin itself based on nixOS. [Software stack](MYBONK-STACK.md).
- **MY₿ONK console**: A full-node bitcoin-only hardware platform designed with anonymity, security, low price, performance, durability, low-enery, supply chain resilience and generic parts in mind.
- **MY₿ONK user**: The end user, you, the family man, the boucher, the baker, the hair dresser, the mecanics... Just want the thing to work, "plug and forget". Uses GUIs and has an aversion to the command line. On MAINNET.
- **MY₿ONK operator**: A "MY₿ONK user" that got really serious about it and decided to learn more, move to the next level. Has some "skin in the game" on MAINNET and is happy to experiment on SIGNET. Many operators take part in nodes Federation or create their own Federation.
- **MY₿ONK hacker**: A "MY₿ONK operator" so deep in the rabbit hole, bitcoin, privacy and sovereignty that he became a MY₿ONK hacker. That's an advanced user, student, Maker, researcher, security expert .etc... Just want to tear things apart. Love to use command line. On SIGNET.

# Overview
This small ecosystem consists of only two elements that we are going to build together:
  
- **One orchestration machine:**
  This machine is used to orchestrate your fleet of MY₿ONK consoles, it is essentially a Linux with a few additional software installed including the Nix package manager.
- **One MY₿ONK console:**
  This machine runs the MY₿ONK stack on NixOS. It is setup once and its configuration can be updated remotly using MY₿ONK orchestration machine.
  
# Advice
- **Don't trust, verify**: Anything you download on the internet is at risk of being malicious software. Know your sources. Always run the GPG (signature) or SHA-256 (hash) verification (typically next to the download link of an image or package there is a sting of hexadecimal characters).
- **Nix vs. NixOS**: It is very important to understand the concept that nix and nixOS are two different things: 
  - Nix is a [package manager](https://en.wikipedia.org/wiki/Package_manager) (something like npm, rpm and others)
  - NixOS is a [full-blow Linux distribution](https://en.wikipedia.org/wiki/NixOS) built on top of the nix package manager. For an overview see [how Nix and NixOS work](https://nixos.org/guides/how-nix-works.html).
  - For a general introduction to the Nix and NixOS ecosystem, see [nix.dev](https://nix.dev/).
- **Read and explore**: The pros write and read documentation, they are not so much on YouTube.

---
---

# 0. ssh and auto login

This is so important that we felt it diserved its own section.

![](docs/img/various/ssh_failed_attempts.gif)

All we do with the machines is over ssh. If you're the kind of person entering his password manually every time this is not going to fly.

Spare yourself the pain and avoid getting locked out of the system by mistake. Take the time to not only understand what ssh is but also how it works, particularily how to use ssh auto login (auto login *using public and private keys pair* to be specific). It is not only a good idea to save time, it is also significantly more secure than simple password-based login. It is also a pre-requisite for the deployment of MY₿ONK.

One opens an encrypted connection with a server using a ssh client. So you have the *ssh client* on the one hand and the *ssh server* on the other hand. ssh clients come in different form and shape, some with nice GUI, but all we do here is on the command line, using the basic ssh client typically bundled with any Linux distribution.

Let's start by showing you how to ssh as user ``user`` from local (your laptop) into whatever remote machine with ip '```REMOTE_MACHINE_IP```' (assuming that user ``user`` exists on the target machine, that you know his password and that the ssh server is running on the target machine).


```
$ ssh user@REMOTE_MACHINE_IP
Last login: Tue Aug 17 04:44:11 2021 from 10.0.2.2
$
```

Log out now. 

```
$ exit
logout
Connection to REMOTE_MACHINE_IP closed.
$
```

Let's setup auto login instead, this will allow you to use the ssh command the same way but loging-in without being prompted for the password. To do this you need what is called a "key pair". Any user can generate a key pair. Generate yours using ```ssh-keygen```. Just hit enter to all the questions, including passphrase.
```
$ ssh-keygen -t rsa -b 4096

Generating public/private rsa key pair.
Enter file in which to save the key (/Users/JayDeLux/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/JayDeLux/.ssh/id_rsa
Your public key has been saved in /Users/JayDeLux/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:RRa2T2DT8Zvc2kkKsF6A3BxvAOqynktDEEnbQMvnwvA Jay@Jay-MacBook-Pro.local
The key's randomart image is:
+---[RSA 4096]----+
|  o=..    Oo..   |
|  ..* o  = +.+   |
| . = + o  o . .  |
|  = = + +. o . *.|
|   E = =So  . =.o|
|  o =   =     .  |
|   =   . o   .   |
|  . o .   . .    |
|   .   .   .     |
+----[SHA256]-----+

```

- ```-t``` stands for type. RSA is the default type so this flag is not really necessary.

- ```-b``` stands for bits. By default the key is 3072 bits long. You can use 4096 bits key for stronger security.

As indicated in the output of the command the key pair has been generated in ```/Users/JayDeLux/.ssh/id_rsa``` 

```
$ ls /Users/JayDeLux/.ssh/id_rsa
id_rsa  id_rsa.pub

$ file /home/debian/.ssh/id_rsa
/Users/JayDeLux/.ssh/id_rsa: OpenSSH private key

file /home/debian/.ssh/id_rsa.pub
/Users/JayDeLux/.ssh/id_rsa.pub: OpenSSH RSA public key
```

As you can see a *public* key (```id_rsa.pub```) and a *private* key (```id_rsa```) have been generated. These are what allow you to connect in a trusted way with the target machine. 

Now we are going to push our public key (```id_rsa.pub```) onto the target machine. 
The easiest way to do this is to use the command ```ssh-copy-id``` which is shipped with the openssh-client package, the synthax is similar to ssh:

Let's enable ssh auto login for our user ```user``` using ```ssh-copy-id``` on the target ```REMOTE_MACHINE_IP```

```
ssh-copy-id user@REMOTE_MACHINE_IP

/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
user@192.168.0.83's password: 

```
Enter the password for the user ```user``` 
```
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'user@192.168.0.83'"
and check to make sure that only the key(s) you wanted were added.
```

Do as instructed, try to ssh and see that you are no longer requested to provide the password.

```
ssh user@REMOTE_MACHINE_IP
Last login: Wed Jan 11 14:00:33 2023 from 192.168.0.7
$ 
```

Now you could do the same with the same certificate to enable ssh auto login for other remote users, even ```root```. However ```root``` being a very special user with "great powers and great responsibilities" its login over ssh is restricted by configuration in most distributions. You don’t want hackers to launch brute force attack to hack into your server, so it’s a good practice to disable password authentication in ssh.


---


Another time saver mechanism is configuring hosts you connect to often in the ssh client's configuration file as explained in details [here](https://goteleport.com/blog/ssh-config/).

In short:


```
nano ~/.ssh/config
```
Copy/past the following:

```
Host mybonk-node-001
    Hostname IP_ADDRESS_OR_HOST_NAME
    User user
    PubkeyAuthentication yes
    IdentityFile ~/.ssh/id_rsa
    AddKeysToAgent yes
```

The parameters are self-explainatory. You need to replace ```IP_ADDRESS_OR_HOST_NAME``` by the target machine IP or full name, ```ùser``` is the remote user; you may need to check ```IdentityFile``` points to your id_rsa generated earlier, remember this file contains your ```private key```.


Now you can ssh into the machine with an easy to remember sythax and all the info needed to make this connection happen will be automatically picked from the corresponding ```Host``` section in the ssh config file.

```
$ ssh mybonk-node-001
```

You can create an many ```Host``` entries as you like in the ssh config file.

---
---

# 1. Build your MYBONK bitcoin full node
  
  There are many ways to do this, the one detailed here focuses on people with little (but still *some*) technical knowledge.
  
  These steps can be automated but the goal for now is to *understand* how it works.
  
### 1.1 The hardware

There are many many platforms, physical (HW) or virtual (Virtual Machines, Cloud) to choose from, which is what NixOS was made for in the first place and this is great. A collection of hardware specific platform profiles to optimize settings for different hardware is even being maintained at [NixOS Hardware repository](https://github.com/NixOS/nixos-hardware/blob/master/README.md)


The following steps focus on MY₿ONK console hardware platform only because it would be impossible to maintain and support all the possible combinations for a specific application domain: Each hardware has its own specs, some have additional features (BIOS capabilities, onboard encrypton, various kinds of storages and partition systems .etc...) or limitations (too little RAM or unreliable parts, weak power source, "moving parts", cooling issues, higher power consumption .etc...) making it unadvisable to install onto, or too difficult for an average person to setup and maintain; Even little things like bootable or not from USB stick can turn what should be a beautiful journey into hours of frustration tring to just make the thing boot until the next pitfall.

MY₿ONK console can also be used to run Raspiblitz similarly to Raspberry pi or other distributions.

### 1.2 Download and install NixOS

  Now we are taking you through the standard steps of installing nixOS on MY₿ONK console. 

  A NixOS live CD image can be downloaded from the [NixOS download page](https://nixos.org/download.html#nixos-iso) to install from (make sure you scroll down to the bottom of the page as the first half of it is about nix *package manager* not nixOS).
  
  Download the "*Graphical* ISO image", it is bigger than the "Minimal ISO image" but it will give you a good first experience using nixOS and will ease some configuration steps like setting up default keyboard layout and disk partitionning which are typical pain points for "not-so-experienced-users". NixOS' new installation wizard in the Graphical ISO image makes it so much more user-friendly.

  Flash the iso image on a USB stick using [balenaEtcher](https://www.balena.io/etcher/).
  
  Plug your MY₿ONK console to the power source and to your network using an RJ45 cable.

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_005.png)


  Plug a keyboard and a screen on your MY₿ONK console (they are used only during this first guided installation procedure, after this all interactions with the MY₿ONK console will be done "headless" via the MY₿ONK orchestration machine as explained in section [Control your MY₿ONK fleet from orchestration machine](#3-basic-operations)).

  Let your MY₿ONK console boot from the USB stick:

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_010.png)

  After the welcome screen the first thing you are asked to configure is the Location, this is used to make sure the system is configured with the correct language and that the corresponding numbers and date formats are used, just choose the right one for you.

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_020.png)

  The next screen is keyboard layout selection, which is invariably a point people struggle with depending on what country they are from (azerty, questy ...) and also the variants that exist. **Take your time** trying a few (don't forget the try characters that are not alphabetical letters such as '@', '*', '_', '-', '/', ';', ':' .etc... ) until you find the best match. In my case it's "French" variant "French (Macintoch)". Not choosing the correct layout will result in keys inversions which will lead to you not being able to log in your system because the password you think you tap is not actually entring the same characters.

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_030.png)
  
  Next you are going to create the users for the system. For now we create a user ```mybonk``` with password ```mybonk``` and we use the same password for the administrator account. 

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_040.png)

  Next you are going to be asked what Desktop you want to have. We don't want a Desktop, select "No desktop" 

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_050.png)

  Next confirm "Unfree software" (read the reason behind this mentionned on the screen)
![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_060.png)


  Next we are going to configure the storage devices and partitions. MY₿ONK console has 2 built-in storage devices:
  - ```/dev/sda``` M1 mSATA 128GB SSD used for *system*: This is where the system boots from, where the operating system (and various caches) lives and where the swap space is allocated. 
  - ```/dev/sdb``` SATA 1TB SSD used for *states*: This is where the system settings, the bitcoin blockchain and installed software settings as well as user data is stored. The data on this drive *persisted* 


![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_062.png)

  As this is a fresh new install these drives should not contain any partitions. If there are any on either of the disks delete them by selecting "New Partition Table" (Creating a new partition table will delete all data on the disk).
  Make sure you select "Master Boot Record (MBR)" instead of GUID Partition Table (GPT) when creating new partition tables
  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_065.png)


  Let's configure ```/dev/sda```:
  
  
  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_070.png)

  Let's configure ```/dev/sdb```:
  
  
  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_080.png)


  Now select "Next" to confirm the partitions that are going created (and possibly prior deleted).

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_090.png)


  The intallation takes less than one minute click on "Toggle Logs" at the bottom right of the splash screen it to see and understand how the OS is being pulled and installed.

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_100.png)

  "All Done". Do **NOT** Unplug the USB stick just yet.

  Select "Restart now" and click on "Done"

  ![](docs/img/NixOS_install_screenshots/NixOS_install_screenshot_110.png)

  When MY₿ONK console is rebooting remove the USB stick it will then boot on the MBR of /dev/sda. Your system is now running by itself let's continue its configuration.

  On the MY₿ONK console (this is the last time we will be using it, going forward we are doing to connect to the MY₿ONK console "headless" using remote ssh) login as user ```mybonk``` password ```mybonk```
  
  ````
  $ ls /etc/nixos
  configuration.nix  hardware-configuration.nix
  ````

  ```configuration.nix``` and ```hardware-configuration.nix``` are the files used to build the running NixOS.

  Look at ```configuration.nix```
  ````
  $ nano /etc/nixos/configuration.nix
  ````
  You can see that most of the options you have been walked through during the installation by the wizard have been transalted into entries in this file. All features and services of the system are configurable through similar simple, human-readable options in this file. 
  
  See [Nix - A One Pager](https://github.com/tazjin/nix-1p) for a short guide to Nix, the language used in ```configuration.nix```. Use [nix repl](https://nixos.wiki/wiki/Nix_command/repl) to interactively explore the Nix language as well as configurations, options and packages in Nixpkgs.

  Now look at ````hardware-configuration.nix````.
  ````
  $ nano /etc/nixos/hardware-configuration.nix
  ````
  This file was generated by the system, you don't normally edit it, make changes to ```configuration.nix``` instead.

  Next thing we want is connect to MY₿ONK console using ssh so we can access it remotly ("headless", that is without a screen nor a keyboard attached). 
  
  However sshd is a service that is not running on MY₿ONK console yet, it is not even installed . Let's do it. 

  ````
  ls -la /etc/nixos/configuration.nix
  -rw-r--r-- 1 root root 3155 ene 16 15:12 /etc/nixos/configuration.nix

  ````
  As you can see ```configuration.nix``` is editable only by *root* so you'll use sudo:

  ````
  sudo nano /etc/nixos/configuration.nix
  ````

  '````services.openssh.enable = true;````' is commented-out. Uncomment it. Also add the extra parameter '````services.openssh.permitRootLogin = "yes";````' to allow user *root* to use ssh too.

  ````
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  ````

  Which could also be written like this:
  ````
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };
  ````

  Save the file and exit. 
  
  [```nixos-rebuild```](https://nixos.wiki/wiki/Nixos-rebuild) is the NixOS command used to apply changes made to the system configuration and various other tasks related to managing the state of a NixOS system. For a full list of sub-commands and options, see the nixos-rebuild man page. 
  ````
  $ man nixos-rebuild
  ````
  
  Build the configuration and activate it, but don't add it (just yet) to the bootloader menu. This is done using the ```test``` subcommand
  ````
  $ nixos-rebuild test
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
  [mybonk@nixos:/etc/nixos]$ sudo journalctl -f -n 60
  ````
  Entries refering to the system change and sshd being enabled are being displayed.

  Confirm it is running:
  ````
  $ systemctl status sshd.service 
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

  The ```switch``` subcommand will not only rebuild the system, it will also activate the new generation immediately and make it the new default option in the bootloader, making your system configuration changes persistant.
  ````
  $ sudo nixos-rebuild switch
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

Your system changes are now persistant after reboot.

Now that sshd has been installed and is running let's ssh in. You need your MY₿ONK console's IP address for this. The IP address has most likely been assigned by your internet router built-in DHCP server. Look for a new device and assigned IP address in your internet router pannel. 

Alternatively you can get it from the command line using the command ```ifconfig``` for instance, MY₿ONK console wired network interface is ```enp2s0```

  ````
  $ ifconfig enp2s0
  enp2s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.64  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 2a02:2788:a4:285:1e48:f4dc:5f3a:afaf  prefixlen 64  scopeid 0x0<global>
        inet6 2a02:2788:a4:285:bb20:a992:d4c4:d6be  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::6f79:4796:6bbe:c73a  prefixlen 64  scopeid 0x20<link>
        ether 68:1d:ef:2e:0c:b3  txqueuelen 1000  (Ethernet)
        RX packets 66069  bytes 7714527 (7.3 MiB)
        RX errors 0  dropped 3459  overruns 0  frame 0
        TX packets 25192  bytes 3267524 (3.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
  ````
  
  You can see its IP address is ```192.168.0.64```.
  To avoid having to remember this IP address we can map it to a hostname on our machine, here '```mybonk_console```' (this is useful to access systems that do not have a DNS entry or if you want to overwrite them in a test or development environment).

  ````
$ echo "192.168.0.64 mybonk_console" | sudo tee -a /etc/hosts
  ````
  OK now you're ready, ssh into your MY₿ONK console from your laptop:

````
$ ssh mybonk@mybonk_console
The authenticity of host 'mybonk_console (192.168.0.64)' can't be established.
ED25519 key fingerprint is SHA256:gyeJzKezZGneNmfKyO5lugfPM3czJImVjkOKjxsDKI4.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:31: 192.168.0.64
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.0.64' (ED25519) to the list of known hosts.
(mybonk@mybonk_console) Password: 
Last login: Mon Jan 16 06:03:35 2023
$
````

Try the same with *root* user
````
$ exit
$ ssh root@mybonk_console 
(root@mybonk_console) Password: 
Last login: Mon Jan 16 06:03:35 2023
#
````

You have learned: 
- How to enable a service (````sshd````) and tune it through Nix configuration ('````services.openssh.enable = true;```` and '```services.openssh.permitRootLogin = "yes";```' in ```configuration.nix```).
- How to use ssh with and without password (using key pair).
- How to test these configuration changes (e.g. ```nixos-rebuild test```, ```systemctl status sshd```, ```journalctl -f -n 30 -u sshd``` ) before making them percistant across reboots (```nixos-rebuild switch```).
 
In the next section we are going to see how we can configure one (or multiple) MY₿ONK console(s) remotly using a MY₿ONK orchestration machine.

13-download-and-install-myonk
### 1.3 Download and install MYBONK 
#### **Option 1.** The way it is done "manually""

Exactly the same way we installed, configured and enabled the service openssh modifying only the nixos configuration file ```configuration.nix``` in the previous section, we can enable all sorts of services and parameters. 

Let's install, configure and run the service ```bitcoind``` and see how it goes. 
A package is readily available for ```bitcoind``` on https://mynixos.com/nixpkgs/package/bitcoind, look at its documentation.

ssh into MY₿ONK console as '```mybonk```':
`````
$ssh mybonk@mybonk_console
Last login: Tue Jan 17 10:42:32 2023 from 192.168.0.7
[mybonk@mybonkgenesis:~]$ 
`````

We are going to create a new file ```node.nix``` in ```/etc/nixos``` to build a basic bitcoin node on it with just a few lines...
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*procedure to be finished here even if it is not going be be used afterwards*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


<a name="13-option-2"></a>
#### **Option 2.** The way it is automated using a MY₿ONK ochrestration machine
  Ref. section [Build your orchestration machine](#build-orchestration).

---

# 2. Build your MYBONK orchestration machine
This machine is used to orchestrate your fleet of MY₿ONK consoles. It does not have to run nixOS (only nix package manager), 
You could use your day to day laptop, note that some pitfalls or required extra steps had been reported to install Nix on macOS (read-only filesystem / single-user/multi-user). 
We suggest you make it easy on yourself and keep things separte by using a Virtual Machine. 

### 2.1. Download and install VirtualBox
Follow the instructions on their website https://www.virtualbox.org

### 2.2. Build the OS
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
  - The login details are typically on the download page (in our case ``debian``/```debian``` and can become ```root``` by using ```$ sudo su -``` ). 
  - Do not use such images in a production environment. 
  - It is common to have issues with keyboard layout when accessing a machine that has been configured in a different language (e.x. the first few letters of the keyboard write ```querty``` instead of ```azerty``` and other keys don't behave normally). There are various ways to adjust this in the configuration but it's out of the scope of this document. The simplest and most effective is to find a way to login using the erroneous keyboard layout anyhow figuring out which key is which then once in the Desktop Environment ajust the settings in "Region & Language" > "Input Source".







Now you need to install some additional pretty common software packages that will be needed to continue. Debian's package manager is [apt](https://www.cyberciti.biz/tips/linux-debian-package-management-cheat-sheet.html?utm_source=Linux_Unix_Command&utm_medium=faq&utm_campaign=nixcmd). Root privileges are required to mofify packages installed on the system which is why we prepend the following commands with [sudo](https://www.cyberciti.biz/tips/linux-debian-package-management-cheat-sheet.html?utm_source=Linux_Unix_Command&utm_medium=faq&utm_campaign=nixcmd).

Update the packages index:

```
$ sudo apt update command
```

Install the additional packages (Debian 11 Bullseye) [curl](https://manpages.org/curl), [git](https://manpages.org/git), ***[gnupg2](), [dirmngr]()***:
```
$ sudo apt install curl git
```

### 2.3. ssh and auto login
First of all you need the IP address of the machine you want to connect to, the MY₿ONK orchestration machine's. As it runs in a Virtual Box you need to make sure the network setting of its virtual machine is set to "*bridge adapter*" for it to be assigned an IP. If unsure have a look at [ssh into a VirtualBox](https://www.golinuxcloud.com/ssh-into-virtualbox-vm/#Method-1_SSH_into_VirtualBox_using_Bridged_Network_Adapter).

Also note that in Debian ssh restrictions apply to ```root``` user: 

In the ssh server configuration '```/etc/ssh/sshd_config```'

Open ```/etc/ssh/sshd_config``` using ```nano /etc/ssh/sshd_config``` and see the setting ```PermitRootLogin``` is indeed ```prohibit-password```. 

Other possible values are ```without-password``` and ```yes```. ```prohibit-password``` and ```without-password``` now ban all interactive authentication methods, allowing only public-key, hostbased and GSSAPI authentication (previously it permitted keyboard-interactive and password-less authentication if those were enabled).

It is generaly advised to avoid using user ```root``` especially to remote-access. You can use ```sudo -i``` from another user instead when needed. 

The value of ```PermitRootLogin``` can remain ```prohibit-password```.


### 2.4. Install Nix
  
  
  #### **Option 1.** Using the ready-made binary distribution from nix cache
  - Quicker and more convenient than Option 2 as it has been pre-built for you.

    ssh into the orchestration machine and run:
    ``` 
    $ sh <(curl -L https://nixos.org/nix/install)   
    ```

    You can see outputs related to Nix binary being downloaded and installed. 

```      
Installation finished!  To ensure that the necessary environment
variables are set, either log in again, or type

  . ~/.nix-profile/etc/profile.d/nix.sh

in your shell.
```
And as instructed run the following command (or logout or login again):

```
. ~/.nix-profile/etc/profile.d/nix.sh

```
      
Check the installation went OK

```
$ nix --version
nix (Nix) 2.12.0
```

Have a first look at the manual
```
$ man nix
```
  

  #### **Option 2.** Building Nix from the source
  - Regarded as the "sovereign" way to do it but takes more time.
  - Follow the instructions on nix page https://nixos.org/nix/manual/#ch-installing-source
  

### 2.4. Build MYBONK stack
Now that the orchestration machine is up and running we can use it to build MY₿ONK stack and deploy it seemlesly to the fleet of MY₿ONK consoles in a secure, controlled and effortless way.

MY₿ONK stack is derived from [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin/). Have a look at their GitHub, especially their [examples](https://github.com/fort-nix/nix-bitcoin/blob/master/examples/README.md) section.

Login to MY₿ONK orchestration machine:

```
ssh debian@mybonk_orchestration
$
```

This MY₿ONK orchestration machine needs root passwordless key pair ssh access to the target MY₿ONK console, let's generate our key pair:

```
ssh-keygen -t rsa -b 4096

Generating public/private rsa key pair.
Enter file in which to save the key (/Users/JayDeLux/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/JayDeLux/.ssh/id_rsa
Your public key has been saved in /Users/JayDeLux/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:RRa2T2DT8Zvc2kkKsF6A3BxvAOsyMktDEEnbQMvnwvA Jay@Jay-MacBook-Pro.local
The key's randomart image is:
+---[RSA 4096]----+
|  o=..    Oo..   |
|  ..* o  = +..   |
| . = + o  o . .  |
|  = = + += o . *.|
|   E = =So  . =.o|
|  o =   =     .  |
|   =   . o   .   |
|  . o .   . .    |
|   .   .   .     |
+----[SHA256]-----+

```
Let's enable ssh auto login for our user ```root``` on the remote MY₿ONK console (192.168.0.64) using ```ssh-copy-id```.
```
debian@debian11:~$ ssh-copy-id root@192.168.0.64
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/debian/.ssh/id_rsa.pub"
The authenticity of host '192.168.0.64 (192.168.0.64)' can't be established.
ED25519 key fingerprint is SHA256:gyeJzKezZGneNmfKyO5lugfPM3czJMmVjkOKjxsDKI4.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
Password: 
```
Enter the password for user ```root``` ('```mybonk```')

```
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.0.64'"
and check to make sure that only the key(s) you wanted were added.

```

Do as instructed, try to ssh and see that you are no longer requested to provide the password.

```
$ ssh root@192.168.0.64
Last login: Tue Jan 17 10:42:43 2023 from 192.168.0.7
# 
```

Exit

````
$ exit
````

Do exactly the same for the user ```mybonk``` (password '```mybonk```').

Let's add shortcuts in ssh config file for these: 

```
$ nano ~/.ssh/config
````

and add the following lines at the end of the file:

```
Host mybonk-console-root
    Hostname 192.168.0.64
    User root
    PubkeyAuthentication yes
    IdentityFile ~/.ssh/id_rsa
    AddKeysToAgent yes

Host mybonk-console-mybonk
    Hostname 192.168.0.64
    User mybonk
    PubkeyAuthentication yes
    IdentityFile ~/.ssh/id_rsa
    AddKeysToAgent yes

```

Now, log-in as ```mybonk```.

```
$ ssh mybonk-console-mybonk
```

Close nin-bitcoin in your home directory:

```
git clone https://github.com/fort-nix/nix-bitcoin
```

This creates a directory ```nix-bitcoin```, have a look inside:

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

It contains the vanilla configuration on top of which we are going to overlay MY₿ONK specificities and features. Don't worry too much trying to figure out what each of these files and directories do, we are not going to modify anything in it, just reuse (copy/past) some of its content.


Get into the ```example``` directory and run the command ```nix-shell```. nix-shell interprets ```shell.nix``` and pulls all the dependancies it refers to. Note that it takes some time to execute:
```
cd examples
nix-shell
```
The output of the command tells us that 117 paths will be fetched (126.56 MiB download, 756.95 MiB unpacked) 

Go back to home directory and create a new directory ```mybonk```

```
cd
mkdir mybonk
cd mybonk
```

Copy the initial files and directory ```nix-bitcoin-release.nix```, ```configuration.nix```, ```shell.nix```, ```krops``` and ```.gitignore``` from ```nix-bitcoin/examples```.

````
cp -r ../nix-bitcoin/examples/{nix-bitcoin-release.nix,configuration.nix,shell.nix,krops,.gitignore} .

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

- ```configuration.nix```: You recognize this file from a previous session.
- ```krops```: Directory used for deployment (described in section [#2.5 Deploy MY₿ONK stack to the MY₿ONK consoles](#25-deploy-mybonk-stack-to-the-mybonk-consoles))
- ```nix-bitcoin-release.nix```: TODO
- ```shell.nix```: TODO


https://nixos.org/manual/nix/stable/command-ref/nix-shell.html



Letconfiguration.nix```: You recognize this file from a previous session.



### 2.5. Deploy MYBONK stack to the MYBONK consoles
  
There are is probably a dozen of options available to deploy a nixOS configuration, each with its pros and cons.
[NixOps](https://github.com/NixOS/nixops/blob/master/README.md), the official DevOps tool of NixOS is nice, but it has some flaws. 

[krops](https://github.com/krebs/krops/blob/master/README.md) is one of these alternatives trying to solve some of these flaws with some very simple concepts; Some of its features are:
- store your secrets in password store
- build your systems remotely
- minimal overhead (it's basically just nixos-rebuild switch!)
- run from custom nixpkgs branch/checkout/fork

We are going to use krops as it is already used and suggested by nix-bitcoin. 

Read [this very well written article](https://tech.ingolf-wagner.de/nixos/krops/) to get an idea of how krops works before you get started.


First, krops needs to ssh MY₿ONK console, specifically automatic login using public key on OpenSSH. We have done this earlier let's move on ...

Make sure you are in the deployment directory (```mybonk```), edit ```krops/deploy.nix```` which is the main deployment configuration file:

Locate the FIXME and set the target to the name of the ssh config entry created earlier, i.e. mybonk-node.

```

```









@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TBD
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

The following command enables evaluating your node config on a machine that has a different system platform than your node.
Examples: Deploying from macOS or deploying from a x86 desktop PC to a Raspberry Pi.

"è'!§fhhhhhhhhhhrfpç!uueeeeeeeuuuuuuuuureeeeer!!!èèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèèd
```
echo "x86_64-linux" > krops/system
echo "aarch64-linux" > krops/system
echo "i686-linux" > krops/system
echo "armv7l-linux" > krops/system
```

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# 3. Basic operations
  
### 3.1. Backup and restore

### 3.2. Join a Federation



