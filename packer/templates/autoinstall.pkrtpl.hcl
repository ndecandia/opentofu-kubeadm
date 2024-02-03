#cloud-config
# vim: set filetype=yaml ts=2 sw=0 expandtab:
autoinstall:
  version: 1
  shutdown: reboot
  refresh-installer:
    update: true
  updates: all
  early-commands:
    - systemctl stop ssh
  late-commands:
    - curtin in-target -- apt-get -y purge unattended-upgrades
  ssh:
    install-server: true
  network:
    version: 2
    ethernets:
      ens192:
        dhcp4: false
        dhcp6: false
        addresses:
          - ${yamlencode(ipv4_address)}
        nameservers:
          addresses:
%{~for addr in dns_servers}
            - ${yamlencode(addr)}
%{~endfor}
        routes:
          - to: default
            via: ${yamlencode(ipv4_gateway)}
  storage:
    swap:
        size: 0
    config:
      - type: disk
        id: disk0
        path: /dev/sda
        preserve: false
        grub_device: true
        wipe: superblock-recursive
        preserve: false
        ptable: gpt
      - type: partition
        id: disk0-part0
        device: disk0
        flag: bios_grub
        size: 1M
      - type: partition
        id: disk0-part1
        device: disk0
        size: -1
      - type: format
        id: disk0-part1-fs0
        fstype: ext4
        label: root
        volume: disk0-part1
      - type: mount
        id: disk0-part1-mount0
        path: /
        device: disk0-part1-fs0
  debconf-selections: |
    cloud-init cloud-init/datasources multiselect NoCloud, OVF, VMware, None
    unattended-upgrades unattended-upgrades/enable_auto_updates boolean false
  user-data:
    power_state:
      mode: poweroff
    hostname: ${yamlencode(hostname)}
    package_update: true
    package_upgrade: true
    package_reboot_if_required: false
    packages:
      - jq
      - net-tools
      - python3-pip
      - tree
      - unzip
      - zip
    user:
      name: ${user}
      gecos: ${user_full_name}
      lock_passwd: false
      groups: [sudo]
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
%{~ for key in ssh_authorized_keys }
        - ${key}
%{~ endfor }
    write_files:
      - path: /etc/cloud/cloud.cfg.d/99-vmware-guest-customization.cfg
        content: |
          disable_vmware_customization: false
      - path: /etc/cloud/cloud.cfg.d/99-users.cfg
        content: |
          # No default users
          users: []
      - path: /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
        content: |
          network: {config: disabled}
      - path: /etc/cloud/cloud.cfg.d/99-ssh.cfg
        content: |
          ssh:
            emit_keys_to_console: false
          ssh_deletekeys: true
          ssh_quiet_keygen: true
      - path: /etc/cloud/cloud.cfg.d/99-disable-cloud-init-on-next-boot.cfg
        content: |
          write_files:
            - path: /etc/cloud/cloud-init.disabled
      - path: /etc/sysctl.d/99-no-swappiness.conf
        content: |
          vm.swappiness = 0
      - path: /etc/default/grub.d/99-packer.cfg
        content: |
          GRUB_TIMEOUT=5
          GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
    runcmd:
      - update-grub
      - sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
      - rm -f -- /etc/netplan/* /etc/cloud/cloud.cfg.d/99-installer.cfg
      - rm -f -- /var/lib/systemd/random-seed /var/lib/systemd/credential.secret
      - cloud-init clean --logs --seed
      - echo uninitialized > /etc/machine-id
      - truncate -c -s 0 /etc/hostname /etc/machine-info
