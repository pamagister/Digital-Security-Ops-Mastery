# 📱 Android Backup & Restore – Übersicht, Checkliste & Strategien

Ziel: **Datenverlust vermeiden**, **Gerätewechsel vereinfachen** und **sensible Daten kontrolliert sichern**.
Der Fokus liegt auf **Android (Google‑Ökosystem)** mit **klaren Backup‑Strategien**, **Checklisten** und **konkreten Anleitungen**.

---

## 🧠 Grundprinzipien einer soliden Backup‑Strategie

* 🔁 **Automatisch + manuell kombinieren**
* 🧱 **Mehr als ein Speicherort** (Cloud + lokal)
* 🔐 **Sensible Daten verschlüsseln**
* 🧪 **Restore regelmäßig testen** (sonst zählt es nicht als Backup)

**Faustregel (3‑2‑1):**

* 3 Kopien
* 2 unterschiedliche Medien
* 1 Kopie extern/offsite

---

## 🔐 Passwörter (KeePass)

### Empfohlene App

* **KeePassDX** (F‑Droid bevorzugt, alternativ Google Play)

### Strategie‑Varianten

#### ✅ Variante A – PC ist Master (konservativ & robust)

* PC hält den **führenden KeePass‑Container (.kdbx)**
* Smartphone bekommt **regelmäßige Kopie**

**Checkliste:**

* [ ] KeePassDX installiert
* [ ] Container auf PC gepflegt
* [ ] Regelmäßige Übertragung auf Smartphone (USB / Sync‑Tool)
* [ ] Zusätzliches Backup des Containers (Cloud + offline)

#### ✅ Variante B – Synchronisiert (komfortabler)

* KeePass‑Container liegt in Cloud (Nextcloud / Dropbox)
* PC **und** Smartphone greifen darauf zu

⚠️ **Achtung:**

> Konflikte möglich → saubere Sync‑Disziplin nötig

**Tipp 💡**

> Cloud‑Ordner nur für KeePass nutzen, nicht wild mischen

---

## 💬 Messenger & Nachrichten

### WhatsApp

* Backup via **Google Drive**

**Checkliste:**

* [ ] Google‑Konto verbunden
* [ ] Backup aktiviert (täglich empfohlen)
* [ ] Medien einbeziehen oder bewusst ausschließen

⚠️ **Achtung:**

> Restore nur mit **gleicher Telefonnummer** möglich

---

### Signal

**Optionen:**

* **A)** Lokales verschlüsseltes Backup
* **B)** Neuer Signal Backup Dienst (30 Tage Medien)

🔗 Quelle: [https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable](https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable)

**Checkliste (lokal):**

* [ ] Backup aktivieren
* [ ] Backup‑Passphrase sicher speichern 💡 KeePass-Container
* [ ] Backup‑Datei regelmäßig extern sichern

⚠️ **Achtung:**

> Ohne Passphrase ist das Backup wertlos

---

### Telegram

* 💡 **Alles serverseitig gespeichert**

✔ Kein Backup nötig

**Tipp 💡**

> Ideal für Notizen & Selbst‑Chats

---

## 📸 Fotos

### Variante A – Google Fotos

* Automatischer Upload
* **Speicherqualität: „Speicherplatz sparen“**

**Checkliste:**

* [ ] Backup aktiviert
* [ ] Richtige Qualität eingestellt

⚠️ **Achtung:**

> Originalqualität frisst Google‑Speicher, reduzierte Qualität aber ebenfalls

---

### Variante B – Dropbox + Dropsync

**Workflow:**

1. Smartphone → Dropbox (per App "Dropsync")
2. PC → Dropbox Sync
3. PC: Fotos **regelmäßig aus Sync‑Ordner verschieben**

**Checkliste:**

* [ ] Dropsync App auf dem Smartphone installiert
* [ ] Fotoordner des Telefons angebunden
* [ ] Dropbox auf dem PC installiert: https://www.dropbox.com/de/install
* [ ] Regelmäßige Bereinigung am PC

💡 **Tipp:**

> Ordnerstruktur nach Jahr/Monat anlegen

---

## 📁 Daten & sensible Dokumente

### Empfohlene Lösung: Nextcloud (Managed)

* Beispiel: hosting.de - **1000 MB kostenlos**
* Ideal für:

  * Pass‑Scans
  * Tickets
  * KeePass‑Container
  * Regelmäßig benötigte Dokumente

**Checkliste:**

* [ ] Nextcloud‑Konto erstellt
* [ ] Android‑App installiert
* [ ] Ordnerstruktur definiert
* [ ] Automatischen Upload konfiguriert

🔐 **Pluspunkt:** Volle Datenkontrolle

---

## ☁️ Cloud‑Vergleich (Fotos & Daten)

| Dienst                   | Vorteile                   | Nachteile                          | Geeignet für      |
| ------------------------ | -------------------------- | ---------------------------------- | ----------------- |
| **Google Drive / Fotos** | Nahtlos, zuverlässig       | Datenschutz, Speicher schnell voll | Mainstream, Fotos |
| **Dropbox**              | Sehr guter Sync, stabil    | Wenig Gratis‑Speicher              | Fotos + Daten     |
| **Managed Nextcloud**    | Volle Kontrolle, DSGVO‑nah | Etwas Setup                        | Sensible Daten    |
| **OneDrive**             | Windows‑Integration        | Android schwächer                  | Office‑lastig     |

---

## 📝 Notizen

### Telegram‑Self‑Group

* Eigene Gruppe nur mit sich selbst
* Immer servergesichert, geht auch ohne Backup nicht verloren

### Nextcloud Notes

* Zentrale Notizen
* Plattformübergreifend

📌 Details siehe: [Nextcloud](../nextcloud/README_de.md)

### Google Keep 

* Cloud-basierter Notizdienst von Google: https://keep.google.com
* Geeignet für: 
  * Schnelle Notizen, Checklisten, temporäre Gedanken, Ideen, To-dos
  * Sprach- und Bildnotizen (OCR inklusive)


> ⚠️ **Achtung:** Kein dediziertes Backup pro Notiz möglich. Löschen = weg (nach Ablauf des Papierkorbs).

> 📌  **Nicht** geeignet als alleinige Quelle für kritische Informationen.


---

## 🔄 System‑Backup (Android‑Bordmittel)

Auf dem Telefon: **Einstellungen** → **Google** → **Sicherung**

**Sichert:**

* App‑Liste
* WLAN‑Passwörter
* Einstellungen

**Checkliste:**

* [ ] Google Backup aktiviert
* [ ] Letztes Backup geprüft

⚠️ **Achtung:**

> App‑Daten nur teilweise

---

## ➕ Weitere sinnvolle Aspekte

* 🔑 **2FA‑Backups** (Aegis / Authy)
* 🧾 **Export kritischer Daten** (CSV, PDF)
* 💾 **Offline‑Backup** (USB‑Stick, verschlüsselt)
* 🧪 **Restore‑Test auf Zweitgerät**

---

## 🧭 Empfohlene Minimal‑Strategie (praxisnah)

* Google Backup → System
* KeePass → PC‑Master + Cloud‑Backup
* Signal → Lokales Backup
* Fotos → Google Fotos **oder** Dropbox‑Workflow
* Daten → Nextcloud

🎯 Ergebnis: **robust, übersichtlich, kontrollierbar** 🚀

---

