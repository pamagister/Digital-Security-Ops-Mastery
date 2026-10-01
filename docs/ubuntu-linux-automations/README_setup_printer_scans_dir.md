# Setting Up Brother MFC-9332CDW to Scan to a Linux Samba Share

This guide walks you through configuring a Brother MFC-9332CDW printer/scanner to save scanned documents directly to a Linux machine via Samba (SMB). It also covers firewall settings, editing `smb.conf`, and troubleshooting.

The included script creates a Samba share under the current user's home directory. Review it before running because it changes `/etc/samba/smb.conf`, installs Samba if needed, and may add a firewall rule.
When UFW is active, the script allows the Samba profile without restricting the source network. Replace that rule with a LAN-scoped rule if the share should only be reachable from your local network.

## 1. Download the script

```bash
curl -fL -o setup_shared_folder_samba.sh https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/ubuntu-linux-automations/scripts/setup_shared_folder_samba.sh
```
   
## 2. Make the Script Executable

```bash
chmod +x setup_shared_folder_samba.sh
```
## 3. Run the script as your regular user

```bash
./setup_shared_folder_samba.sh
```

The script does not create a Samba password. Add/enable a Samba password for the Linux account that owns the share:

```bash
sudo smbpasswd -a "$USER"
sudo smbpasswd -e "$USER"
```

---

✨ You can also set up a samba share manually:

## Step 1: Create a Samba Share

1. Create a folder on your Linux machine where scans will be stored:

```bash
mkdir -p /home/USERNAME/Scans
```

2. Set appropriate ownership and permissions:

```bash
sudo chown -R USERNAME:USERNAME /home/USERNAME/Scans
sudo chmod -R 775 /home/USERNAME/Scans
```

### 🧪 Verification

* From the Linux machine:

```bash
ls -ld /home/USERNAME/Scans
```

  You should see the folder owned by `USERNAME` with `rwxrwxr-x` permissions.

---

## Step 2: Install Samba (if not installed)

```bash
sudo apt update
sudo apt install samba
```

### 🧪 Verification

* Check Samba status:

```bash
sudo systemctl status smbd
```

  It should be `active (running)`.

---

## Step 3: Configure Samba (`/etc/samba/smb.conf`)

1. Backup the original configuration:

```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
```

2. Open the file in Kate (or your preferred editor):

```bash
sudo kate /etc/samba/smb.conf
```

3. Add the following share at the bottom of the file:

```ini
[Scans]
path = /home/USERNAME/Scans
browseable = yes
writable = yes
guest ok = no
valid users = USERNAME
create mask = 0664
directory mask = 0775
```

4. Do not lower Samba's minimum protocol to SMB1/NT1. Use SMB2 or newer; if an old printer only supports SMB1, update its firmware or isolate/replace it rather than weakening the server for every client.
5. Save and validate the configuration:

```bash
sudo testparm -s
```

6. Restart Samba:

```bash
sudo systemctl restart smbd
```

### 🧪 Verification

* Test the share from Linux:

```bash
smbclient -L localhost -U USERNAME
```

  You should see `Scans` listed under Sharename.
* From another PC (Windows/Linux):

```bash
smb://<linux-hostname>/Scans
or
\\user-pc-name.local\Scans
```

  Enter `USERNAME` and your Samba password to verify access.

---

## Step 4: Create or enable a Samba account

The share uses `valid users = USERNAME`, so the Linux account must also have a Samba password:

```bash
sudo smbpasswd -a USERNAME
sudo smbpasswd -e USERNAME
smbclient //localhost/Scans -U USERNAME
```

## Step 5: Configure the firewall

Allow SMB only from your trusted local network. Replace the example subnet with your LAN's actual subnet:

```bash
sudo ufw allow from 192.168.1.0/24 to any app Samba
sudo ufw status
```

Do not expose SMB ports to the public internet. If UFW is inactive, adding a rule alone does not enable the firewall; configure firewall policy deliberately before enabling it. Test access from another device on the trusted network.

---

✨ Finally, configure the printer:

## Last step: Configure your printer, e.g. Brother MFC-9332CDW

1. Access the printer Web interface:

```
http://<printer-ip>/
e.g. 
http://192.168.0.155
```

   Login with admin credentials.
   --> You can get the printer ip by navigating to Einstellungen - Alle Einstellungen - Ausdrucke in the printer and make a test print 

2. Navigate to (if available):

```
Network → Protocol → CIFS
```

   * Enable CIFS.
   * Set **SMB Version** to `Auto` or `SMBv2` (if available).
   * Set **Authentication Method** to `NTLMv2`.

3. Configure a “Scan to Network” profile:

   * **Host-Adresse:** `linux-hostname` (do **not** include domain here)
   * **Zielordner:** `Scans`
   * **Benutzername:** `USERNAME` (or a workgroup-qualified form if required by the printer)
   * **Password:** The Samba password you set for `USERNAME`
   * **Dateityp, Qualität, etc.:** As preferred

4. Apply settings and reboot the printer.

### 🧪 Verification

* On the printer panel:

```
Scan → to Network → [Configured Profile]
```

* Scan a test document.
* Confirm the file appears in `/home/USERNAME/Scans/` on the Linux machine.

---

## Troubleshooting

### 🔹 If the printer cannot connect:

* Verify Samba is running:

```bash
sudo systemctl status smbd
```
  
* Confirm the folder exists and has proper permissions.
* Test access from another PC using the same credentials.
* Make sure the firewall permits SMB from the trusted local network only.

### 🔹 If SMB protocol mismatch occurs:

* Update CIFS settings on the Brother printer to use SMBv2 or Auto.
* Do not enable SMB1/NT1 globally. Update the printer firmware and select SMB2 or newer. If that is impossible, use an isolated network and understand the security risk.
* Validate and restart Samba after configuration changes:

```bash
sudo testparm -s
sudo systemctl restart smbd
```

### 🔹 If scan fails intermittently:

* Check network connectivity.
* Ensure the host name resolves from the printer (try using IP instead of hostname).
* Verify the Samba user credentials are correct.

---

## ✅ Summary

With a supported SMB version, a Samba account, and firewall access restricted to the trusted LAN, the printer can save scans directly to the Linux share.
