![English](../_static/ico/uk.ico)[English](README_en.md) | ![Deutsch](../_static/ico/germany.ico)[Deutsch](README.md) 

# Einrichten eines kindersicheren Telefons

In diesem Kapitel geht es darum, ein Mobiltelefon einzurichten, das von Kindern sicher benutzt werden kann.
Der Schwerpunkt liegt dabei auf der Gewährleistung der folgenden Funktionen:

- Begrenzung der Bildschirmzeit für bestimmte Anwendungen und Kategorien von Anwendungen
- Erschweren der Installation und Deinstallation bestimmter Apps (abhängig von Android-Version und Gerät)
- Schutz der App zur Begrenzung der Bildschirmzeit; eine Drittanbieter-App kann Deinstallation oder Umgehung nicht zuverlässig verhindern
- Schutz vor unangemessenen Inhalten
- Lokalisierung des Telefons im Falle eines Verlustes oder zur Bestimmung des Aufenthaltsortes des Kindes


## Empfohlene Apps

- ![app_image](../_static/ico/timelimit.ico) **[TimeLimit](https://timelimit.io/)** auf [f-droid](https://f-droid.org/packages/io.timelimit.android.aosp.direct/): Flexibel die Nutzungsdauer begrenzen 
- ![app_image](../_static/ico/adaway.ico) **[AdAway](https://adaway.org/)** auf [f-droid](https://f-droid.org/de/packages/org.adaway/): Ein kostenloser und quelloffener Werbeblocker für Android
- ![app_image](../_static/ico/applock.ico) **[App Lock](https://play.google.com/store/apps/details?id=applock.lockapps.fingerprint.password.lockit)**: Drittanbieter-App zum Sperren ausgewählter Apps. Die Sperre ist keine verlässliche Kindersicherung und kann je nach Gerät umgangen werden.
- ![app_image](../_static/ico/findmydevice.ico) **[Find My Device](https://f-droid.org/packages/de.nulide.findmydevice/)**: Gerät per SMS orten und bestimmte Fernbefehle ausführen


---

## Gerät einrichten

### App zur Begrenzung der Bildschirmzeit einrichten

1. Installieren Sie TimeLimit [wie oben erwähnt](#empfohlene-apps)
1. Erteilen Sie die notwendigen Berechtigungen
1. Fügen Sie mindestens die folgenden Apps als explizit erlaubte Apps hinzu, damit diese Apps ungehindert arbeiten können:
   * AdAway-Inhaltsblocker
   * App-Sperre
1. Sperren Sie diese Apps vollständig (Zeitlimit 0)
   * Einstellungen (Dies erhöht die Sicherheit gegen unautorisierte Deinstallationen)
1. Setzen Sie nach Bedarf Zeitlimits

<Details>
<summary>ℹ️ Tipps und Details zur Bildschirmzeitbegrenzungs-App</summary>

Um die Bildschirmzeit zu begrenzen, können einzelne Apps mit der oben genannten App in Kategorien eingeteilt werden.
Für jede dieser Kategorien kann ein individuelles Zeitlimit eingestellt werden.

Ein Problem ist, dass das Bildschirmzeitlimit eher ein Selbstkontrollmechanismus ist. 
Es lässt sich zwar eine Stecknadel einrichten, die aber sehr leicht umgangen werden kann, zum Beispiel durch Deinstallation oder Deaktivierung der App. 
Daher ist es notwendig, die Zeitlimit-App mit einer App zur generellen Sperrung anderer Apps zu kombinieren, siehe unten.
</details>

---

### Inhaltsblocker einrichten

1. Installieren Sie AdAway [wie oben erwähnt](#empfohlene-apps)

2. Fügen Sie bei Bedarf einige individuelle Blocklisten hinzu:

   * StevenBlack Unified hosts: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

   * StevenBlack Fakenews-Glücksspiel-Porno: https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-only/hosts

   * Online-Spiele: https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/child-proof-phone/online-games-hosts-blocklist/hosts


<Details>
<summary>ℹ️ Tipps und Details zum Inhaltsblocker</summary>

* Weitere Details finden Sie in einer ausführlichen Erklärung in diesem [Blogpost](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/) (deutsch).
* Die meisten Geräte haben keine Root-Rechte, so dass Sie sich auf den VPN-basierten Werbeblocker verlassen müssen.
* Vergessen Sie nicht, die Quellen regelmäßig zu aktualisieren und die gewünschte Funktion des Werbeblockers zu überprüfen.
</details>


<Details>
<summary>Verwendung vereinheitlichter gesperrter Hosts</summary>

Zusätzlich zu den bereits voreingestellten gesperrten Hosts können weitere Hosts [hier](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants) gefunden werden.
Die Liste **Unified Hosts** ist häufig voreingestellt. Für Kinder können zusätzliche Kategorien wie [Glücksspiel und Pornografie](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts) ergänzt werden. Prüfen Sie jede Liste auf Aktualität und Nebenwirkungen.
</details>


<Details>
<summary>Individuelle Sperrlisten erstellen</summary>

In manchen Fällen wird es notwendig sein, zusätzliche Seiten individuell zu sperren, wie z.B. **Onlinespiele**. 
Weitere Informationen dazu finden Sie im [AdAway Wiki](https://github.com/AdAway/AdAway/wiki/HostsSources).

Eine zusätzliche [Hostliste zum Blockieren von Online-Spielen](https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/child-proof-phone/online-games-hosts-blocklist/hosts) liegt in diesem Repository.
Diese basiert auf der AdBlock-kompatiblen Liste von [IREK-szef](https://raw.githubusercontent.com/IREK-szef/games-blocklist/main/lists/Adblock-dns/games.txt), die an das AdAway-Format angepasst und leicht erweitert wurde.
</details>

---

### App Locker einrichten

1. Installieren Sie die gewünschte App [wie oben erwähnt](#empfohlene-apps)
1. Erteilen Sie die notwendigen Berechtigungen
1. Sperren Sie mindestens die folgenden Apps:

   1. AdAway Content Blocker (zur Verhinderung von Löschungen von Hostblocklisten)
   
   2. App zur Begrenzung der Bildschirmzeit (auch wenn die App zur Begrenzung der Bildschirmzeit ihre eigene Sicherheit hat, erhöht dies die Sicherheit gegen unerwünschte Manipulationen)
   
   3. Einstellungen (dies verhindert die Deinstallation)

1. App-Einstellungen anpassen

   1. 🔴 **[aus]** Fingerabdruck verwenden (würde das Entsperren mit dem Fingerabdruck der Kinder ermöglichen)
   2. 🟢 **[ein]** Neue App sperren
   3. 🟢 **[ein]** Ein Passwort oder eine PIN festlegen, die sich von der PIN des Kindes unterscheidet
   4. 🔴 **[aus]** Akku-Optimierung für die App (damit sie im Hintergrund weiterlaufen kann; der genaue Schaltername hängt von Android ab)
   5. 🟢 **[ein]** Symboltarnung
   6. 🟢 **[ein]** Deinstallationsschutz


<Details>
<summary>ℹ️ Tipps und Details zu App Locker</summary>

* Eine App-Sperre kann Änderungen erschweren, verhindert aber nicht zuverlässig, dass eine App deaktiviert oder deinstalliert wird. Geräte-PIN, Android-Version und Berechtigungen beeinflussen die Umgehungsmöglichkeiten.
* Das Sperren der Einstellungen ist keine verlässliche Kindersicherung. Prüfen Sie, ob die App im Hintergrund aktiv bleibt und ob die Schutzfunktionen auf dem konkreten Gerät funktionieren.
* Sie kann auch dazu verwendet werden, harmlose Apps zu schützen, die eine spezielle Konfiguration benötigen (z.B. nextcloud), die vom Kind nicht verändert werden soll.
</details>


---

### Find My Device einrichten

Die App Find My Device muss auf dem Gerät installiert sein, das geortet werden soll. Autorisieren Sie alle Geräte, von denen aus Fernbefehle per SMS gesendet werden dürfen, zuerst auf diesem Gerät.
Alle Einstellungen müssen also auf dem zu ortenden Gerät vorgenommen werden, z.B. die Telefonnummer des Kindes.

Ortung und Fernbefehle können sensible Standort- und Gerätedaten offenlegen oder Daten löschen. Verwenden Sie diese Funktionen transparent, mit Zustimmung und nur entsprechend den geltenden Regeln. Prüfen Sie die aktuelle App-Dokumentation, bevor Sie Befehle nutzen; `fmd delete` setzt das Gerät zurück und löscht lokale Daten.

Auf dem zuvor autorisierten Gerät wird der entsprechende Befehl per SMS gesendet:

```
fmd locate - sendet den aktuellen GPS-Standort
fmd ring - löst ein Klingeln des Telefons aus
fmd lock - sperrt das Telefon
fmd stats - sendet Gerätedetails
fmd delete - setzt das Telefon auf die Werkseinstellungen zurück
fmd camera (back/front) - nimmt ein Foto mit der gewählten Kamera auf und sendet es an den konfigurierten Server
```

---

## Weitere Links

- AdAway: [Ausführliche Beschreibung der Funktionalität (deutsch)](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/)
- FindMyDevice: [github Wiki](https://github.com/ColoursofOSINT/findmydevice/tree/main)