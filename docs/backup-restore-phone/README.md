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

## 🌐 Browser-Sync als zusätzliches Sicherheitsnetz

> 💡 **Ergänzung, kein Ersatz für KeePass.**
> Hilft bei **Passwörtern, Logins und Lesezeichen** – besonders bequem bei Handy-Wechsel.

---

### Warum das sinnvoll ist

* Ein Login → **gleiche Daten auf PC & Smartphone**
* Wiederherstellung bei neuem Gerät in Minuten
* Automatische Sicherung von:
  * Passwörtern
  * Lesezeichen
  * Verlauf (optional)

---

### Empfohlene Browser

* 🦊 Firefox (sehr gut geeignet)
* 🌍 Google Chrome (falls ohnehin Google genutzt wird)


**Checkliste:**

☐ Browser (Firefox oder Chrome) auf PC & Smartphone identisch
☐ Mit gleichem Login (Firefox) oder Google-Konto anmelden
☐ Synchronisation aktivieren

---

### Wichtige Hinweise ⚠️

* Browser-Sync **ersetzt KeePass nicht**
* Kritische Logins (Bank, E-Mail, Apple/Google-ID) weiterhin in KeePass


---

### Bewährte Praxis

* **KeePass = Tresor**
* **Browser = Alltag**

💡 Passwörter dürfen ruhig **an zwei Stellen existieren**,
**solange KeePass die Referenz bleibt.**

---

### Mini-Check (30 Sekunden)

☐ Browser auf PC & Handy identisch
☐ Login aktiv
☐ Lesezeichen auf beiden Geräten sichtbar
☐ Ein gespeichertes Passwort testweise abrufen


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

* **Alles serverseitig gespeichert** → ✔ Kein Backup nötig
* Besser als der Telegram Messenger vom Play Store ist die Open-Source-Variante **"Forkogram"** von F-Droid
* Dort muss jedoch ein altes Zweit-Gerät oder der Browser im Telegram-Konto angemeldet sein, damit man über die "alte" Telegram-Instanz den Anmeldecode empfangen kann, um auf dem neuen **Forkogram**-Gerät den Account zu aktivieren

**Tipp 💡**

> 1. Ideal für Notizen & Selbst‑Chats
> 2. Immer ein Zweitgerät oder den PC via https://web.telegram.org verbunden haben, um das neue Gerät kostenfrei mit der bestehenden Nummer zu verbinden

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

📌 Details siehe: [Nextcloud](../nextcloud/README.md)

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

