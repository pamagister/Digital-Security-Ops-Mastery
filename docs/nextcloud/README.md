![English](../_static/ico/uk.ico)[English](README_en.md) | ![Deutsch](../_static/ico/germany.ico)[Deutsch](README.md) 

# Einführung

## Warum Nextcloud?

Nextcloud ist eine Open-Source-Plattform für Dateispeicherung und Zusammenarbeit. Je nach installierten Apps und Konfiguration lassen sich auch Kalender, Kontakte und Notizen synchronisieren. Bei selbst gehosteten Installationen sind Sie selbst für Updates, Zugriffsschutz, Backups und Wiederherstellung verantwortlich.

## Die wichtigsten Funktionen von Nextcloud

1. **Datenkontrolle und Datenschutz:** Beim eigenen Hosting verwalten Sie Speicherort und Zugriffe selbst. Der Schutz hängt jedoch von Serverkonfiguration, Updates, Zugangsdaten und Backups ab.
1. **Anpassung und Flexibilität:** Das Selbst-Hosting ermöglicht es Ihnen, Nextcloud an Ihre speziellen Bedürfnisse anzupassen. Sie können zusätzliche Anwendungen installieren, die Benutzeroberfläche anpassen und sie mit anderen Diensten und Tools integrieren.
1. **Kosteneffizienz:** Auch wenn anfangs Kosten für die Einrichtung anfallen, kann Self-Hosting auf lange Sicht kosteneffizient sein. Es fallen keine wiederkehrenden Abonnementgebühren an, und Sie können die Hardware wählen, die zu Ihrem Budget passt.
1. **Skalierbarkeit:** Mit der selbst gehosteten Nextcloud haben Sie die Flexibilität, Ihre Infrastruktur entsprechend Ihren Anforderungen zu skalieren. Dies ist besonders vorteilhaft für Unternehmen oder Einzelpersonen mit wachsendem Speicherbedarf.
1. **Konfigurierbare Sicherheit:** Sie können Sicherheitsmaßnahmen wie Firewall, Verschlüsselung und Updates selbst verwalten. Das schafft Verantwortung und erfordert regelmäßige Wartung.
1. **Offline-Zugriff:** Die selbst gehostete Nextcloud ermöglicht den Offline-Zugriff auf Ihre Dateien. Dies ist besonders nützlich, wenn Sie sich in Umgebungen ohne konstante Internetverbindung befinden.
1. **Kollaborationsfunktionen:** Nextcloud bietet eine Reihe von Kollaborationstools, einschließlich Dateifreigabe, Kalender, Kontakte und gemeinsame Dokumentenbearbeitung. Wenn Sie selbst gehostet werden, können diese Tools auf Ihre speziellen Anforderungen an die Zusammenarbeit zugeschnitten werden.
1. **Integration mit bestehenden Systemen:** Das Self-Hosting von Nextcloud ermöglicht eine nahtlose Integration mit Ihrer bestehenden Infrastruktur und Ihren Authentifizierungssystemen. Dies kann die Benutzerverwaltung rationalisieren und die Benutzererfahrung kohärenter gestalten.
1. **Community-Support:** Die Nextcloud-Community ist aktiv und bietet Unterstützung durch Foren, Dokumentation und andere Kanäle. Durch das Selbst-Hosten können Sie von dieser kollaborativen Umgebung profitieren.
1. **Lernchance:** Das Hosting von Nextcloud auf Ihrem eigenen Server bietet Ihnen eine wertvolle Lernerfahrung. Es ermöglicht Ihnen, Ihr Verständnis für die Serveradministration, Sicherheitspraktiken und die Funktionsweise von Cloud-Diensten zu vertiefen.



Berücksichtigen Sie vor dem Selbsthosting Ihre technischen Kenntnisse, verfügbare Ressourcen und den laufenden Wartungsaufwand. Eine Synchronisierung ist kein unabhängiges Backup: Planen und testen Sie separate Sicherungen.


# Einrichten von Nextcloud

## Einrichten eines Nextcloud-Servers

Als Alternative zu Cloud-Diensten können Sie Nextcloud selbst betreiben oder einen Managed-Nextcloud-Anbieter wählen. Prüfen Sie bei gehosteten Angeboten Speicherlimit, Datenschutzbedingungen, Backups und Wiederherstellungsoptionen direkt beim Anbieter; Tarife und Funktionen ändern sich.
Für die Synchronisation mit dem eigenen PC gibt es auch die Nextcloud PC Client Software, um die Dateien zwischen Nextcloud, dem Telefon und dem PC zu synchronisieren.

## Installieren Sie die benötigten Apps auf dem mobilen Gerät

1. ![app_image](../_static/ico/fdroid.ico) **F-Droid**: Katalog für freie und quelloffene Apps. Open Source allein ist keine Sicherheitsgarantie; prüfen Sie Herausgeber, Berechtigungen und Aktualisierungen.
1. ![app_image](../_static/ico/nextcloud.ico) **Nextcloud**: Client zum Synchronisieren von Dateien und für automatische Uploads. Kontakte, Kalender und Aufgaben werden üblicherweise über DAVx⁵ mit CardDAV/CalDAV synchronisiert.
1. ![app_image](../_static/ico/davx5.ico) **DAVx⁵**: DAVx⁵ ist eine CalDAV/CardDAV-Verwaltungs- und Synchronisations-App für Android, die sich nahtlos in Kalender- und Kontakt-Apps integrieren lässt. Mit DAVx⁵ haben Sie Ihre Kontakte, Termine und Aufgaben auf Ihrem eigenen Server oder einem vertrauenswürdigen CalDAV/CardDAV-Dienst unter Ihrer eigenen Kontrolle.
1. ![app_image](../_static/ico/nextcloudnotes.ico) **[Nextcloud Notes](https://f-droid.org/de/packages/it.niedermann.owncloud.notes/)**: Anzeigen und Bearbeiten von Notizen auf Nextcloud
1. ![app_image](../_static/ico/opentasks.ico) **[OpenTasks](https://f-droid.org/de/packages/org.dmfs.tasks/)**: Eine Aufgabenmanager-App, mit der Sie Ihre ToDo-Liste nach Dringlichkeit, Status, Zeitrahmen usw. kategorisieren können.

## Nextcloud-Server konfigurieren

1. Richten Sie den Nextcloud-Dienst bei einem Anbieter Ihrer Wahl ein oder betreiben Sie ihn selbst.
1. Aktivieren Sie auf dem Server die benötigten Apps und Funktionen (z. B. Kalender, Kontakte, Notizen und Aufgaben). Menüs und verfügbare Apps unterscheiden sich je nach Anbieter und Nextcloud-Version.
1. Speichern Sie Serveradresse und Zugangsdaten in einem Passwortmanager. Geben Sie Passwörter nicht in gemeinsam genutzten oder unverschlüsselten Notizen ab.
1. Melden Sie sich in der Nextcloud-App mit der Serveradresse und Ihrem Konto an. Erteilen Sie nur die für die gewünschten Funktionen erforderlichen Berechtigungen.
1. Richten Sie DAVx⁵ mit der Serveradresse und den Zugangsdaten ein. Wählen Sie die gewünschten CardDAV-Adressbücher und CalDAV-Kalender aus. Verfügbarkeit und Einrichtung hängen von Server und Android-Version ab.
1. Installieren und konfigurieren Sie bei Bedarf OpenTasks für Aufgaben und Nextcloud Notes für Notizen; prüfen Sie, welche Server-Apps und Integrationen erforderlich sind.
1. Installieren Sie ggf. Collabora, um die Dokumente in der Nextcloud öffnen und bearbeiten zu können.

## Kontakte synchronisieren

Die Synchronisierung der Kontakte kann anfangs etwas knifflig sein. Vorgehensweise:
1. Kontakte im bestehenden System (z.B. google) ordentlich vorbereiten und ggf. gruppieren, so dass sie auch in "eigene Kontakte" und "mit Partner/Familie geteilte Kontakte" etc. unterteilt werden können.
1. Kontakte aus google als VCF-Datei(en) exportieren
1. Erstellen Sie bei Bedarf Kontaktgruppen im Adressbuch oder in DAVx⁵. Die Bearbeitungsmöglichkeiten hängen vom Server und der Kontakte-App ab. Synchronisieren Sie anschließend erneut.
1. Kopieren Sie die VCF-Dateien auf das Telefon oder synchronisieren Sie sie über Nextcloud mit dem Telefon
1. Importieren Sie die VCF-Dateien über die Kontakte-App (nicht die Kalender-App) in die gewünschten Adressbücher. Die Menübezeichnungen unterscheiden sich je nach Android-Gerät.

## Weitere Tipps zu Nextcloud

* Teilen Sie Zugangsdaten nicht zwischen mehreren Personen, wenn getrennte Zugriffsrechte wichtig sind. Verwenden Sie nach Möglichkeit getrennte Konten und gezielte Freigaben. Ein gemeinsam genutztes Konto bietet keine verlässliche Trennung persönlicher Daten.
