# Setting Up Brother MFC-9332CDW to Scan to a Linux Samba Share

This guide walks you through configuring a Brother MFC-9332CDW printer/scanner to save scanned documents directly to a Linux machine via Samba (SMB). It also covers firewall settings, editing `smb.conf`, and troubleshooting.

✨ You can also use a script to setup a network device:

## 1. Download the script

```bash
wget https://github.com/pamagister/Digital-Security-Ops-Mastery/blob/main/ubuntu-linux-automations/scripts/setup_shared_folder_samba.sh
```
   
## 2. Make the Script Executable

```bash
chmod +x ~/setup_shared_folder_samba.sh
```
## 2. Run the Script

```bash
./setup_shared_folder_samba.sh
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

4. In the `[global]` section, add these lines to support both SMBv1 (for older Brother firmware) and SMBv2/3:

```ini
server min protocol = NT1
server max protocol = SMB3
```

5. Save and close the file.

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

## Step 4: Configure Firewall

1. Allow Samba through the firewall:

```bash
sudo ufw allow Samba
sudo ufw status
```

### 🧪 Verification

* You should see rules allowing Samba ports (137, 138, 139, 445) in the output of:

```bash
sudo ufw status
```
  
* You should see something like

```bash
Status: active

To                         Action      From
--                         ------      ----
Samba                      ALLOW       Anywhere                  
Samba (v6)                 ALLOW       Anywhere (v6)    
```

* From another machine, verify you can browse the share.

---

## Step 5: Optionally for verification: Create a Samba User

```bash
sudo smbpasswd -a USERNAME
```

* Enter a password when prompted.
* Enable the user:

```bash
sudo smbpasswd -e USERNAME
```

### 🧪 Verification

* Test login:

```bash
smbclient //localhost/Scans -U USERNAME
```

  You should be able to connect and list the folder contents.

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
   * **Benutzername:** `local\USERNAME`
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
* Make sure the firewall allows Samba.

### 🔹 If SMB protocol mismatch occurs:

* Update CIFS settings on the Brother printer to use SMBv2 or Auto.
* Ensure Samba allows NT1 (SMBv1) if using older firmware:
* In the [global] section, add:

```ini
[global]
server min protocol = NT1
server max protocol = SMB3
```

* Now, Save and restart Samba:

```ini
sudo systemctl restart smbd
```

### 🔹 If scan fails intermittently:

* Check network connectivity.
* Ensure the host name resolves from the printer (try using IP instead of hostname).
* Verify the Samba user credentials are correct.

---

## ✅ Summary

By following this guide, your MFC-9332CDW can scan directly to a Linux machine via Samba, accessible from other devices on the network, with proper firewall configuration and authentication.

