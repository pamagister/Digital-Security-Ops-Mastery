[:uk: English](README.md) | [:de: Deutsch](README_de.md) 

# Einrichten eines kindersicheren Telefons
In diesem Kapitel geht es darum, ein Mobiltelefon einzurichten, das von Kindern sicher benutzt werden kann.
Der Schwerpunkt liegt dabei auf der Gewährleistung der folgenden Funktionen:
- Begrenzung der Bildschirmzeit für bestimmte Anwendungen und Kategorien von Anwendungen
- Verhindern der Installation und Deinstallation von bestimmten Apps
- Verhinderung der Deinstallation der App, die zur Begrenzung der Bildschirmzeit erforderlich ist
- Schutz vor unangemessenen Inhalten
- Lokalisierung des Telefons im Falle eines Verlustes oder zur Bestimmung des Aufenthaltsortes des Kindes


<a name="empfohlen" />

## Empfohlene Apps

- ![app_image](../res/ico/timelimit.ico) **[TimeLimit](https://timelimit.io/)** auf [f-droid](https://f-droid.org/packages/io.timelimit.android.aosp.direct/): Flexibel die Nutzungsdauer begrenzen 
- ![app_image](../res/ico/adaway.ico) **[AdAway](https://adaway.org/)** auf [f-droid](https://f-droid.org/de/packages/org.adaway/): Ein kostenloser und quelloffener Werbeblocker für Android
- ![app_image](../res/ico/applock.ico) **[App Lock](https://play.google.com/store/apps/details?id=applock.lockapps.fingerprint.password.lockit)**: AppLock sichert Apps und schützt Ihre privaten Daten mit nur einem Klick. Schützen Sie Ihr Telefon mit einer PIN, einem Muster oder einem Fingerabdruck
- ![app_image](../res/ico/findmydevice.ico) **[Find My Device](https://f-droid.org/de/packages/de.nulide.findmydevice/)** auf [f-droid]((https://f-droid.org/de/packages/de.nulide.findmydevice/)): Lokalisieren und steuern Sie Ihr Gerät aus der Ferne


## Gerät einrichten

### App zur Begrenzung der Bildschirmzeit einrichten
⚡ Schnellstart ⚡ 
1. Installieren Sie die erforderliche TimeLimit App [wie oben erwähnt](#empfohlen)
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

### Inhaltsblocker einrichten
⚡ Schnellstart ⚡
1. Installieren Sie die erforderliche Ad-Blocker-App [wie oben erwähnt](#empfohlen)
1. Fügen Sie bei Bedarf einige individuelle Blocklisten hinzu:
   * StevenBlack Unified hosts: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   * StevenBlack Fakenews-Glücksspiel-Porno: https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-only/hosts
   * Online Gaming: https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/child-proof-phone/online-games-hosts-blocklist/hosts


<Details>
<summary>ℹ️ Tipps und Details zum Inhaltsblocker</summary>

* Weitere Details finden Sie in einer ausführlichen Erklärung in diesem [Blogpost](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/) (deutsch).
* Die meisten Geräte haben keine Root-Rechte, so dass Sie sich auf den VPN-basierten Werbeblocker verlassen müssen.
* Vergessen Sie nicht, die Quellen regelmäßig zu aktualisieren und die gewünschte Funktion des Werbeblockers zu überprüfen.
</details>


<Details>
<summary>Verwendung vereinheitlichter gesperrter Hosts</summary>

Zusätzlich zu den bereits voreingestellten gesperrten Hosts, können weitere spezielle Hosts [hier](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants) gefunden werden.
Die Liste der **Unified Hosts** ist oft schon voreingestellt, so dass für Kinder spezifische Kategorien wie [Glücksspiel und Porno](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts) oder weitere Hosts aus [Stephen Black Hosts](https://github.com/StevenBlack/hosts) hinzugefügt werden können. 
</details>


<Details>
<summary>Individuelle Sperrlisten erstellen</summary>

In manchen Fällen wird es notwendig sein, zusätzliche Seiten individuell zu sperren, wie z.B. **Onlinespiele**. 
Weitere Informationen dazu finden Sie im [AdAway Wiki](https://github.com/AdAway/AdAway/wiki/HostsSources).

Eine zusätzliche [Hostliste zum Blockieren von Online-Spielen](https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/child-proof-phone/online-games-hosts-blocklist/hosts) wurde hier in diesem Repository mit AdAway erstellt. 
Diese basiert auf der AdBlock-kompatiblen Liste von [IREK-szef](https://raw.githubusercontent.com/IREK-szef/games-blocklist/main/lists/Adblock-dns/games.txt), die an das AdAway-Format angepasst und leicht erweitert wurde.
</details>


### App Locker einrichten
⚡ Schnellstart ⚡.
1. Installieren Sie die gewünschte App [wie oben erwähnt](#empfohlen)
1. Erteilen Sie die notwendigen Berechtigungen
1. Sperren Sie mindestens die folgenden Apps:

   * AdAway Content Blocker (zur Verhinderung von Löschungen von Hostblocklisten)
   * App zur Begrenzung der Bildschirmzeit (auch wenn die App zur Begrenzung der Bildschirmzeit ihre eigene Sicherheit hat, erhöht dies die Sicherheit gegen unerwünschte Manipulationen)
   * Einstellungen (dies verhindert die Deinstallation)
1. App-Einstellungen anpassen
   * 🔴 **[aus]** Fingerabdruck verwenden (würde das Entsperren mit dem Fingerabdruck der Kinder ermöglichen)
   * 🟢 **[ein]** Neue App sperren
   * 🟢 **[ein]** Passwort oder Pin festlegen, die sich von der Pin der Kinder unterscheidet
   * 🔴 **[aus]** Batterieoptimierung (dies kann dazu führen, dass die App im Hintergrund inaktiv läuft)
   * 🟢 **[ein]** Symboltarnung
   * 🟢 **[ein]** Deinstallationsschutz


<Details>
<summary>ℹ️ Tipps und Details zu App Locker</summary>

* Um zu verhindern, dass die oben erwähnte App deaktiviert oder gar deinstalliert wird, kann mit App Lock eine Zugriffssperre für bestimmte Apps eingerichtet werden.
* Auch das Einstellungsmenü kann über diese App gesichert werden, um zu verhindern, dass die Lock-App deinstalliert wird. Hierfür muss eine Wiederherstellungs-E-Mail eingerichtet werden.
* Sie kann auch dazu verwendet werden, harmlose Apps zu schützen, die eine spezielle Konfiguration benötigen (z.B. nextcloud), die vom Kind nicht verändert werden soll.
</details>


### Find my Device einrichten
Die App Find my Device muss auf dem Handy installiert sein, das z.B. im Falle eines Verlustes geortet werden soll.
Außerdem müssen alle Geräte, die die Erlaubnis haben sollen, das Gerät per SMS zu orten, zunächst auf dem zu ortenden Gerät autorisiert werden.
Alle Einstellungen müssen also auf dem zu ortenden Gerät vorgenommen werden, z.B. die Telefonnummer des Kindes.



Die App bietet eine intuitive Menüführung für die Einrichtung.

## Weitere Links
- AdAway: [Ausführliche Beschreibung der Funktionalität (deutsch)](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/)