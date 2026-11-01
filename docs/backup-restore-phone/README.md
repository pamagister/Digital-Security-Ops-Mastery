# 📱 Android Backup & Restore – Overview, Checklist & Strategies

Goal: **avoid data loss**, **simplify device change** and **back up sensitive data in a controlled manner**. The focus is on **Android (Google ecosystem)** with **clear backup strategies**, **checklists** and **concrete guides**.

---

## 🧠 Basic principles of a solid backup strategy

* 🔁 **Combine automatic + manual**
* 🧱 **More than one storage location** (cloud + local)
* 🔐 **Encrypt sensitive data**
* 🧪 **Test restore regularly** (otherwise it doesn't count as a backup)

**Rule of thumb (3-2-1):**

* 3 copies
* 2 different media
* 1 copy external/offsite

Synchronization (e.g. Nextcloud, Dropbox or a photo upload) is not an independent backup: accidental deletion, malware or account loss can affect synchronized copies. Keep at least one versioned or separately stored backup and test the restoration.

---

## 🔐 Passwords (KeePass)

### Recommended app

* **KeePassDX** (F-Droid preferred, alternatively Google Play)

### Strategy variants

#### ✅ Variant A – PC is master (conservative & robust)

* PC holds the **leading KeePass container (.kdbx)**
* Smartphone gets a **regular copy**

**Checklist:**

* [ ] KeePassDX installed
* [ ] Container maintained on PC
* [ ] Regular transfer to smartphone (USB / sync tool)
* [ ] Additional encrypted backup of the container, including a separately stored copy

#### ✅ Variant B – Synchronized (more convenient)

* KeePass container is in cloud (Nextcloud / Dropbox)
* PC **and** smartphone access it

⚠️ **Caution:**

> Conflicts possible → clean sync discipline needed

Do not edit the same database simultaneously on multiple devices. Wait for the sync to complete fully and keep a restorable backup of the `.kdbx` file.

**💡 Tip**

> Use cloud folder only for KeePass, don't mix wildly

---

## 🌐 Browser sync as an additional safety net

> 💡 **Supplement, not a replacement for KeePass.**
> Helps with **passwords, logins and bookmarks** – especially convenient when changing phones.

### Why this makes sense

* One login → **same data on PC & smartphone**
* Restoration on new device in minutes
* Automatic backup of:
  * Passwords
  * Bookmarks
  * History (optional)

### Recommended browsers

* 🦊 Firefox (very suitable)
* 🌍 Google Chrome (if Google is used anyway)

**Checklist:**

☐ Browser (Firefox or Chrome) identical on PC & smartphone
☐ Sign in with same login (Firefox) or Google account
☐ Enable synchronization

### Important notes ⚠️

* Browser sync **does not replace KeePass**
* Critical logins (bank, email, Apple/Google-ID) continue in KeePass

Avoid unnecessary password copies in multiple cloud services. Protect every synchronization account used with a strong, unique password and multi-factor authentication.

### Mini-check (30 seconds)

☐ Browser on PC & phone identical
☐ Login active
☐ Bookmarks visible on both devices
☐ Retrieve a saved password as a test

## 💬 Messenger & messages

### WhatsApp

* Backup via **Google Drive**

**Checklist:**

* [ ] Google account connected
* [ ] Backup enabled (daily recommended)
* [ ] Include media or deliberately exclude

⚠️ **Caution:**

> For restoration, usually the same phone number and access to the associated Google account are needed. With activated end-to-end encrypted backup, keys or password must additionally be available.

### Signal

**Options:**

* **A)** Local encrypted backup
* **B)** Further Signal backup options may be available depending on app version and region. Follow the current official instructions instead of relying on a fixed runtime or feature.

🔗 Source: [https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable](https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable)

**Checklist (local):**

* [ ] Enable backup
* [ ] Securely store backup passphrase 💡 KeePass container
* [ ] Regularly back up backup file externally

⚠️ **Caution:**

> Without passphrase the backup is worthless

### Telegram

* Normal cloud chats are synchronized with the Telegram account. **Secret Chats** are device-bound and not transferred to new devices.
* Do not rely solely on account or service availability for important data. Export required content regularly and check official Telegram apps and their sources.
* Enable additional account protection measures and keep access to your phone number and recovery methods.

## 📸 Photos

### Variant A – Google Photos

* Automatic upload
* **Storage quality: "Save storage space"**

**Checklist:**

* [ ] Backup enabled
* [ ] Correct quality set

⚠️ **Caution:**

> Original quality consumes Google storage, reduced quality does too

### Variant B – Dropbox + Dropsync

**Workflow:**

1. Smartphone → Dropbox (via "Dropsync" app)
2. PC → Dropbox sync
3. PC: regularly copy photos into a **separate backup target** and check the backup

**Checklist:**

* [ ] Dropsync app installed on smartphone
* [ ] Phone photo folder connected
* [ ] Dropbox installed on PC: https://www.dropbox.com/de/install
* [ ] Independent, as versioned as possible backup set up

💡 **Tip:**

> A folder structure by year/month makes later checking easier.

**Important:** Deleting or moving in the Dropbox sync folder is usually synchronized with the cloud. Do not delete anything there before an independent backup has been created and checked.

---

## 📁 Data & sensitive documents

### Possible solution: Nextcloud (managed)

* Check storage space, privacy terms, retention and restoration options with the provider; tariffs change.
* Example: hosting.de - **1000 MB free**
* Suitable for:

  * Passport scans
  * Tickets
  * KeePass containers
  * Regularly needed documents

**Checklist:**

* [ ] Nextcloud account created
* [ ] Android app installed
* [ ] Folder structure defined
* [ ] Automatic upload configured

🔐 With a managed service, the provider manages the servers. Do not rely on synchronization as the only backup and check which end-to-end encryption is actually enabled.

---

## ☁️ Cloud comparison (photos & data)

| Service | Advantages | Disadvantages | Suitable for |
| ------- | ---------- | ------------- | ------------ |
| **Google Drive / Photos** | Seamless, reliable | Data privacy, storage quickly full | Mainstream, photos |
| **Dropbox** | Very good sync, stable | Little free storage | Photos + data |
| **Managed Nextcloud** | Provider choice, configurable shares | Trust in provider needed; data privacy and backups must be checked | Files and data |
| **OneDrive** | Windows integration | Android weaker | Office-heavy |

---

## 📝 Notes

### Telegram self-group

* Own group only with yourself
* Always server-secured, not lost even without backup

### Nextcloud notes

* Central notes
* Cross-platform

📌 Details see: [Nextcloud](../nextcloud/README.md)

### Google Keep

* Cloud-based note service from Google: https://keep.google.com
* Suitable for:

  * Quick notes, checklists, temporary thoughts, ideas, to-dos
  * Voice and image notes (OCR included)

> ⚠️ **Caution:** No dedicated backup per note possible. Delete = gone (after trash expires).

> 📌 **Not** suitable as sole source for critical information.

---

## 🔄 System backup (Android built-in)

On the phone: **Settings** → **Google** → **Backup**

**Can back up depending on Android version, manufacturer and settings:**

* App list
* Wi-Fi passwords
* Settings

**Checklist:**

* [ ] Google backup enabled
* [ ] Last backup checked

⚠️ **Caution:**

> The backup is incomplete: not all app data is backed up or can be restored on another device. Check backup status and requirements of respective apps. Google backup requires a Google account and may not be available on a de-googled device.

---

## ➕ Further useful aspects

* 🔑 **2FA emergency preparedness:** Back up Aegis export or recovery method separately and encrypted; keep recovery codes offline. Regularly check whether the export is still readable.
* 🧾 **Export critical data** (CSV, PDF)
* 💾 **Offline backup** (USB stick, encrypted)
* 🧪 **Restore test on secondary device**

---

## 🧭 Recommended minimal strategy (practical)

* Google backup → system
* KeePass → PC master or carefully synchronized database plus independent backup
* Signal → local backup
* Photos → Google Photos **or** Dropbox workflow
* Data → Nextcloud

🎯 Result: **robust, clear, controllable** 🚀

---
