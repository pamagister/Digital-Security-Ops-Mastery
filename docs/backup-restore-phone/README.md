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

Synchronisierung (z. B. Nextcloud, Dropbox oder ein Foto-Upload) ist kein unabhängiges Backup: versehentliches Löschen, Schadsoftware oder ein Kontoverlust können sich auf synchronisierte Kopien auswirken. Halten Sie mindestens eine versionierte oder getrennt aufbewahrte Sicherung vor und testen Sie die Wiederherstellung.

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
* [ ] Zusätzliches verschlüsseltes Backup des Containers, darunter eine getrennt aufbewahrte Kopie

#### ✅ Variante B – Synchronisiert (komfortabler)

* KeePass‑Container liegt in Cloud (Nextcloud / Dropbox)
* PC **und** Smartphone greifen darauf zu

⚠️ **Achtung:**

> Konflikte möglich → saubere Sync‑Disziplin nötig

Bearbeiten Sie dieselbe Datenbank nicht gleichzeitig auf mehreren Geräten. Warten Sie den Sync vollständig ab und bewahren Sie eine wiederherstellbare Sicherung der `.kdbx`-Datei auf.

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

Vermeiden Sie unnötige Passwortkopien in mehreren Cloud-Diensten. Schützen Sie jedes verwendete Synchronisierungskonto mit einem starken, einzigartigen Passwort und Mehr-Faktor-Authentifizierung.

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

> Für die Wiederherstellung werden in der Regel dieselbe Telefonnummer und Zugriff auf das zugehörige Google-Konto benötigt. Bei aktivierter Ende-zu-Ende-verschlüsselter Sicherung müssen außerdem Schlüssel oder Passwort verfügbar sein.

---

### Signal

**Optionen:**

* **A)** Lokales verschlüsseltes Backup
* **B)** Weitere Signal-Sicherungsoptionen können je nach App-Version und Region verfügbar sein. Folgen Sie der aktuellen offiziellen Anleitung, statt sich auf eine feste Laufzeit oder Funktion zu verlassen.

🔗 Quelle: [https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable](https://support.signal.org/hc/de/articles/360007059752-Nachrichten-sichern-und-wiederherstellen#android_enable)

**Checkliste (lokal):**

* [ ] Backup aktivieren
* [ ] Backup‑Passphrase sicher speichern 💡 KeePass-Container
* [ ] Backup‑Datei regelmäßig extern sichern

⚠️ **Achtung:**

> Ohne Passphrase ist das Backup wertlos

---

### Telegram

* Normale Cloud-Chats werden mit dem Telegram-Konto synchronisiert. **Secret Chats** sind gerätegebunden und werden nicht auf neue Geräte übertragen.
* Verlassen Sie sich für wichtige Daten nicht allein auf die Verfügbarkeit des Kontos oder des Dienstes. Exportieren Sie benötigte Inhalte regelmäßig und prüfen Sie die offiziellen Telegram-Apps und deren Bezugsquellen.
* Aktivieren Sie zusätzliche Kontoschutzmaßnahmen und halten Sie Zugriff auf Ihre Telefonnummer und Wiederherstellungsmethoden.

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
3. PC: Fotos regelmäßig in ein **separates Backup-Ziel kopieren** und die Sicherung prüfen

**Checkliste:**

* [ ] Dropsync App auf dem Smartphone installiert
* [ ] Fotoordner des Telefons angebunden
* [ ] Dropbox auf dem PC installiert: https://www.dropbox.com/de/install
* [ ] Unabhängiges, möglichst versioniertes Backup eingerichtet

💡 **Tipp:**

> Eine Ordnerstruktur nach Jahr/Monat erleichtert die spätere Prüfung.

**Wichtig:** Löschen oder Verschieben im Dropbox-Sync-Ordner wird in der Regel mit der Cloud synchronisiert. Löschen Sie dort nichts, bevor eine unabhängige Sicherung erstellt und geprüft wurde.

---

## 📁 Daten & sensible Dokumente

### Mögliche Lösung: Nextcloud (Managed)

* Prüfen Sie Speicherplatz, Datenschutzbedingungen, Aufbewahrung und Wiederherstellungsoptionen beim Anbieter; Tarife ändern sich.
* Beispiel: hosting.de - **1000 MB kostenlos**
* * Geeignet für:

  * Pass‑Scans
  * Tickets
  * KeePass‑Container
  * Regelmäßig benötigte Dokumente

**Checkliste:**

* [ ] Nextcloud‑Konto erstellt
* [ ] Android‑App installiert
* [ ] Ordnerstruktur definiert
* [ ] Automatischen Upload konfiguriert

🔐 Bei einem Managed-Dienst verwaltet der Anbieter die Server. Verlassen Sie sich nicht auf Synchronisierung als einziges Backup und prüfen Sie, welche Ende-zu-Ende-Verschlüsselung tatsächlich aktiviert ist.

---

## ☁️ Cloud‑Vergleich (Fotos & Daten)

| Dienst                   | Vorteile                   | Nachteile                          | Geeignet für      |
| ------------------------ | -------------------------- | ---------------------------------- | ----------------- |
| **Google Drive / Fotos** | Nahtlos, zuverlässig       | Datenschutz, Speicher schnell voll | Mainstream, Fotos |
| **Dropbox**              | Sehr guter Sync, stabil    | Wenig Gratis‑Speicher              | Fotos + Daten     |
| **Managed Nextcloud**    | Anbieterwahl, konfigurierbare Freigaben | Vertrauen in Anbieter nötig; Datenschutz und Backups prüfen | Dateien und Daten |
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

**Kann je nach Android-Version, Hersteller und Einstellungen sichern:**

* App‑Liste
* WLAN‑Passwörter
* Einstellungen

**Checkliste:**

* [ ] Google Backup aktiviert
* [ ] Letztes Backup geprüft

⚠️ **Achtung:**

> Die Sicherung ist unvollständig: Nicht alle App-Daten werden gesichert oder lassen sich auf einem anderen Gerät wiederherstellen. Prüfen Sie den Sicherungsstatus und die Anforderungen der jeweiligen Apps. Google-Backup setzt ein Google-Konto voraus und ist auf einem de-googelten Gerät möglicherweise nicht verfügbar.

---

## ➕ Weitere sinnvolle Aspekte

* 🔑 **2FA-Notfallvorsorge:** Aegis-Export bzw. Wiederherstellungsmethode separat und verschlüsselt sichern; Wiederherstellungscodes offline aufbewahren. Prüfen Sie regelmäßig, ob der Export noch lesbar ist.
* 🧾 **Export kritischer Daten** (CSV, PDF)
* 💾 **Offline‑Backup** (USB‑Stick, verschlüsselt)
* 🧪 **Restore‑Test auf Zweitgerät**

---

## 🧭 Empfohlene Minimal‑Strategie (praxisnah)

* Google Backup → System
* KeePass → PC-Master oder sorgfältig synchronisierte Datenbank plus unabhängiges Backup
* Signal → Lokales Backup
* Fotos → Google Fotos **oder** Dropbox‑Workflow
* Daten → Nextcloud

🎯 Ergebnis: **robust, übersichtlich, kontrollierbar** 🚀

---
