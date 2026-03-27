#!/bin/bash

# 1. Make script executable:
#    >> chmod +x auto-update-setup.sh
# 2. Run script once:
#    >> ./auto-update-setup.sh
# 3. Daily updates, unattended, automatically. Enjoy!

echo "=== Auto Update Setup startet ==="

# Paketlisten aktualisieren
sudo apt update

# unattended-upgrades installieren
sudo apt install -y unattended-upgrades apt-listchanges

# automatische Updates aktivieren
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo "=== Konfiguriere Auto-Upgrades ==="

sudo bash -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF'

echo "=== Erweiterte unattended-upgrades Konfiguration ==="

sudo bash -c 'cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
        "\${distro_id}:\${distro_codename}";
        "\${distro_id}:\${distro_codename}-security";
        "\${distro_id}:\${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
EOF'

echo "=== Aktiviere systemd Timer ==="

sudo systemctl enable unattended-upgrades
sudo systemctl restart unattended-upgrades

echo "=== Testlauf ==="
sudo unattended-upgrade --dry-run --debug

echo "=== Fertig ==="
echo "System aktualisiert sich jetzt automatisch."