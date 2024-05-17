[:uk: English](README.md) | [:de: Deutsch](README_de.md) 

# Einführung

## Warum Nextcloud?

Nextcloud ist eine vielseitige Open-Source-Plattform, die eine sichere Speicherung von Dateien und Zusammenarbeit ermöglicht. Neben der Synchronisierung von Dateien ermöglicht sie auch die nahtlose Synchronisierung von Kalendern, Kontakten und Notizen. Nextcloud bietet eine einheitliche Lösung für den nahtlosen Zugriff und die Zusammenarbeit über verschiedene Geräte hinweg und gewährleistet so effiziente und synchronisierte persönliche und berufliche Arbeitsabläufe.

## Die wichtigsten Funktionen von Nextcloud
1. **Datenkontrolle und Datenschutz:** Wenn Sie Nextcloud auf Ihrem eigenen Server hosten, haben Sie die volle Kontrolle über Ihre Daten. Sie entscheiden, wo sie gespeichert werden, wer Zugriff darauf hat und wie sie verwaltet werden, was Ihre Privatsphäre schützt.
1. **Anpassung und Flexibilität:** Das Selbst-Hosting ermöglicht es Ihnen, Nextcloud an Ihre speziellen Bedürfnisse anzupassen. Sie können zusätzliche Anwendungen installieren, die Benutzeroberfläche anpassen und sie mit anderen Diensten und Tools integrieren.
1. **Kosteneffizienz:** Auch wenn anfangs Kosten für die Einrichtung anfallen, kann Self-Hosting auf lange Sicht kosteneffizient sein. Es fallen keine wiederkehrenden Abonnementgebühren an, und Sie können die Hardware wählen, die zu Ihrem Budget passt.
1. **Skalierbarkeit:** Mit der selbst gehosteten Nextcloud haben Sie die Flexibilität, Ihre Infrastruktur entsprechend Ihren Anforderungen zu skalieren. Dies ist besonders vorteilhaft für Unternehmen oder Einzelpersonen mit wachsendem Speicherbedarf.
1. **Erhöhte Sicherheit:** Sie haben die direkte Kontrolle über die auf Ihrem Server implementierten Sicherheitsmaßnahmen. Dazu gehören die Auswahl von Verschlüsselungsmethoden, die Konfiguration von Firewalls und die Überwachung von Sicherheitsupdates, um die Abhängigkeit von externen Anbietern zu verringern.
1. **Offline-Zugriff:** Die selbst gehostete Nextcloud ermöglicht den Offline-Zugriff auf Ihre Dateien. Dies ist besonders nützlich, wenn Sie sich in Umgebungen ohne konstante Internetverbindung befinden.
1. **Kollaborationsfunktionen:** Nextcloud bietet eine Reihe von Kollaborationstools, einschließlich Dateifreigabe, Kalender, Kontakte und gemeinsame Dokumentenbearbeitung. Wenn Sie selbst gehostet werden, können diese Tools auf Ihre speziellen Anforderungen an die Zusammenarbeit zugeschnitten werden.
1. **Integration mit bestehenden Systemen:** Das Self-Hosting von Nextcloud ermöglicht eine nahtlose Integration mit Ihrer bestehenden Infrastruktur und Ihren Authentifizierungssystemen. Dies kann die Benutzerverwaltung rationalisieren und die Benutzererfahrung kohärenter gestalten.
1. **Community-Support:** Die Nextcloud-Community ist aktiv und bietet Unterstützung durch Foren, Dokumentation und andere Kanäle. Durch das Selbst-Hosten können Sie von dieser kollaborativen Umgebung profitieren.
1. **Lernchance:** Das Hosting von Nextcloud auf Ihrem eigenen Server bietet Ihnen eine wertvolle Lernerfahrung. Es ermöglicht Ihnen, Ihr Verständnis für die Serveradministration, Sicherheitspraktiken und die Funktionsweise von Cloud-Diensten zu vertiefen.



Auch wenn das Selbsthosten von Nextcloud diese Vorteile bietet, ist es wichtig, dass Sie Ihre technischen Fähigkeiten, die verfügbaren Ressourcen und den erforderlichen Wartungsaufwand berücksichtigen, bevor Sie sich für eine selbst gehostete Lösung entscheiden.


# Einrichten von Nextcloud

## Einrichten eines Nextcloud-Servers
Als Alternative zu verschiedenen großen Tech-Clouds (Google, Dropbox) können Sie Ihre eigene Nextcloud einrichten, z.B. auf einem Raspberry, oder alternativ eine gehostete "Managed Nextcloud" wählen. 
Eine eingeschränkte, aber dennoch empfehlenswerte und kostenlose Nextcloud wird von https://www.hosting.de/ angeboten.
Für die Synchronisation mit dem eigenen PC gibt es auch die Nextcloud PC Client Software, um die Dateien zwischen Nextcloud, dem Telefon und dem PC zu synchronisieren.

## Installieren Sie die benötigten Apps auf dem mobilen Gerät
1. ![app_image](../res/ico/fdroid.ico) **F-Droid**: Alternativer Playstore mit generell sicheren Open-Source-Apps
1. ![app_image](../res/ico/nextcloud.ico) **Nextcloud**: Synchronisations-Client für die Nextcloud-App, Basis für die Synchronisation von Dateien, Kontakten, Kalendern, Aufgaben, etc.
1. ![app_image](../res/ico/davx5.ico) **DAVx⁵**: DAVx⁵ ist eine CalDAV/CardDAV-Verwaltungs- und Synchronisations-App für Android, die sich nahtlos in Kalender- und Kontakt-Apps integrieren lässt. Mit DAVx⁵ haben Sie Ihre Kontakte, Termine und Aufgaben auf Ihrem eigenen Server oder einem vertrauenswürdigen CalDAV/CardDAV-Dienst unter Ihrer eigenen Kontrolle.

## Nextcloud-Server konfigurieren
1. Richten Sie den Nextcloud-Dienst ein, z.B. bei Hosting.de. 
1. Nextcloud so konfigurieren, dass die entsprechenden Funktionen des Dienstes zur Verfügung stehen. Aktivieren Sie dazu die Nextcloud-Funktion online bei hosting.de und die entsprechenden Apps im App Center (Kalender, Kontakte, Notizen, Aufgaben, etc.).
1. Notieren Sie sich die Serveradresse zusammen mit dem Passwort (am besten in einer Passwortverwaltung wie KeePass auf dem PC gespeichert). Das ist etwa so: https://xxxxxxxxxxxxxxxxxxxx.Nextcloud.hosting.zone 
1. Tipp: Um die (hoffentlich langen und damit sicheren) Passwörter leichter zur Hand zu haben, empfiehlt es sich, den Passwort-Container KeePass.kdbx an dieser Stelle per USB vom PC auf das Telefon zu übertragen und dann mit KeePassDX zu verwenden.
1. Richten Sie die Nextcloud-App ein: Öffnen Sie die Nextcloud-App und melden Sie sich mit der Serveradresse an. → Dann "Mit dem Konto verbinden", indem man die hosting.de-Zugangsdaten über "Login" eingibt. → Schließlich muss der Nextcloud-App die Berechtigung zum Zugriff auf das Dateisystem des Telefons erteilt werden. 
1. DAVx5 einrichten: Öffnen Sie die DAVx5-App → Berechtigungen erteilen → Konto hinzufügen mit "URL und Benutzername" (geben Sie hier wieder die Serveradresse, den hosting.de-Benutzernamen und das Passwort ein. Nun können Sie die gewünschten CARDDAV-Kontakte und CALDAV-Kalender auswählen, die synchronisiert werden sollen. Die Integration in die nativen Android-Apps wie Kalender und Kontakte erfolgt automatisch. Die OpenTasks-App wird nun ebenfalls synchronisiert.
1. Installieren Sie ggf. Collabora, um die Dokumente in der Nextcloud öffnen und bearbeiten zu können.

## Kontakte synchronisieren
Die Synchronisierung der Kontakte ist anfangs etwas knifflig. Hier ist eine kleine Anleitung zum Vorgehen
1. Kontakte im bestehenden System (z.B. google) ordentlich vorbereiten und ggf. gruppieren, so dass sie auch in "eigene Kontakte" und "mit Partner/Familie geteilte Kontakte" etc. unterteilt werden können.
1. Kontakte aus google als VCF-Datei(en) exportieren
1. Erstellen Sie die entsprechenden Gruppen für die Kontakte über DAVx5. Achtung - der Name der Gruppe und der Beschreibungstext können später nicht mehr geändert werden. Klicken Sie in DAVx5 erneut auf Synchronisieren
1. Kopieren Sie die VCF-Dateien auf das Telefon oder synchronisieren Sie sie über Nextcloud mit dem Telefon
1. nun in der regulären Kalender-App über Einstellungen → Importieren die Kontakte aus der VCF in die jeweilige Kontaktgruppe

## Weitere Tipps zu Nextcloud
* Der kostenlose Tarif der Managed Nextcloud von hosting.de erlaubt nur einen Nutzer. Es können jedoch mehrere Kalender und Kontaktgruppen angelegt werden, die dann jeweils nur von einem Partner genutzt werden können (also für die Synchronisation gedacht sind) oder gemeinsam genutzt werden können, z.B. für einen Familienkalender. Sie teilen sich dann ein einziges Nextcloud-Konto und können praktisch alle Kalender und Kontakte einsehen, aber nur die abonnieren, zu denen Sie auf Vertrauensbasis berechtigt sind.
