#cloud-config
autoinstall:
  version: 1
  locale: en_US
  keyboard:
    layout: us
  network:
    version: 2
    ethernets:
      any:
        match:
          name: en*
        addresses:
          - "${vm_ip}/${vm_cidr}"
        gateway4: "${vm_gateway}"
        nameservers:
          addresses: [${vm_dns}]
  identity:
    hostname: ubuntu-template
    username: ${ssh_username}
    # Locked password — login via SSH key only
    password: "!"
  ssh:
    install-server: true
    authorized-keys:
      - "${ssh_public_key}"
    allow-pw: false
  packages:
    - qemu-guest-agent
    - python3
    - python3-pip
    - curl
    - wget
    - vim
    - htop
    - net-tools
    - ca-certificates
    - gnupg
    - lsb-release
    - unattended-upgrades
  late-commands:
    - "curtin in-target -- systemctl enable qemu-guest-agent"
    - "curtin in-target -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config"
  user-data:
    disable_root: true
    users:
      - name: ${ssh_username}
        groups: sudo
        shell: /bin/bash
        lock_passwd: true
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - "${ssh_public_key}"