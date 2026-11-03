# Plan: Sortiervergleich – temp/Segeln_JTC → temp/tidy_fs_tool

## Ziel

Die unsortierten Dateien unter `temp/Segeln_JTC/` werden mit `fs_tool`
(`tools/fs_tool/`) inventarisiert, inhaltlich nach Logik und thematischer
Zusammengehörigkeit gruppiert und nicht primär nach Datum, Dateityp etc.
unter `temp/tidy_fs_tool/` kopiert, durch einen Inhalt-Vergleich verifiziert
und der gesamte Vorgang in `temp/tidy_report.md` protokolliert.

## Platzhalter

| Platzhalter | Bedeutung | Beispiel |
|-------------|-----------|----------|
| `[TS]` | Zeitstempel des Laufs | `20261103_143000` |
| `[SRC]` | Quellverzeichnis | `temp/Segeln_JTC` |
| `[DST]` | Zielverzeichnis | `temp/tidy_fs_tool/$TS` |
| `[REPORT]` | Berichtdatei | `temp/tidy_report.md` |

## Schritt 0: Arbeitsverzeichnis und Pfade festlegen

```bash
cd /home/paul/PycharmProjects/Digital-Security-Ops-Mastery
TS=$(date +%Y%m%d_%H%M%S)
SRC="temp/Segeln_JTC"
DST="temp/tidy_fs_tool/$TS"
REPORT="temp/tidy_report.md"
LOG="$DST/sortierlog.txt"
```

## Schritt 1: Werkzeug bereitstellen

```bash
python -m pip install -e tools/fs_tool
```

Alternativ direkt ausführbar:

```bash
PYTHONPATH=tools/fs_tool/src python -m fs_tool.main --help
```

Mutationen benötigen `--yes`; zum Prüfen ohne Ausführung `--dry-run`.

## Schritt 2: Quellinventar erstellen (Referenz)

```bash
fs-tool inventory temp/Segeln_JTC > "[DST]/inventory_source.json"
```

Prüfen Sie die Ausgabe auf `"complete": true` und notieren Sie
`entry_count` sowie `tree_sha256`.

## Schritt 5: Dateien kopieren

Kopieren Sie jede Quelldatei in den passenden Zielordner (thematisch gruppiert):

```bash
fs-tool copy [QUELLE] [ZIEL] --yes
```

## Schritt 6: Verifikation durch Inhalt-Vergleich

```bash
fs-tool compare temp/Segeln_JTC "[DST]"
```

Vergleichen Sie Quelle und Ziel, um sicherzustellen, dass keine Datei fehlt
oder beschädigt wurde. Der Vergleich erfolgt nach Inhalt (SHA-256), nicht nach
Pfad oder Name.

## Schritt 7: Bericht schreiben (`temp/tidy_report.md`)

Erstellen Sie `[REPORT]` mit folgendem Inhalt (Beispielstruktur, füllen Sie
 die tatsächlichen Werte ein):

```markdown
# Sortierbericht: temp/Segeln_JTC → temp/tidy_fs_tool/[TS]

**Datum:** YYYY-MM-DD HH:MM  
**Werkzeug:** fs_tool  
**Quelle:** temp/Segeln_JTC/  
**Ziel:** temp/tidy_fs_tool/[TS]/  

## Zusammenfassung

- Quelldateien insgesamt: <Anzahl>
- Erfolgreich kopiert: <Anzahl>
- Fehlgeschlagen: <Anzahl>
- Vergleich vollständig: <ja/nein>
- Fehlende Einträge nach Vergleich: <Anzahl>

## Sortier-Logik

Dateien wurden nach thematischer Zusammengehörigkeit gruppiert unter
`temp/tidy_fs_tool/[TS]/`.

## Werkzeugaufrufe (für Token-Einschätzung)

| Schritt | Aufruf | Richtung | Geschätzte Token |
|---------|--------|----------|------------------|
| 2 | inventory | Eingabe/Ausgabe | <n> |
| 4 | mkdir × N | Eingabe | <n> |
| 5 | copy × N | Eingabe | <n> |
| 6 | compare | Eingabe/Ausgabe | <n> |
| **Gesamt** | | | **<n>** |

## Verifikation

- `complete`: <true/false>
- `missing_entry_count`: <n>
- `errors`: <n>
- Exit-Code (fs_tool): <n>

## Fazit

Der Sortiervorgang war <erfolgreich / teilweise erfolgreich / fehlgeschlagen>.
```

## Schritt 8: Token-Verbrauch einschätzen

1. **Eingabe:** Größe des Aufrufs (Pfadnamen, Parameter, JSON) in Zeichen.
2. **Ausgabe:** Größe der Rückgabe (insbesondere Inventar- und Vergleichs-JSON).
3. Grobe Faustregel: ca. 4 Zeichen ≈ 1 Token (Deutsch/Englisch gemischt).
4. Tragen Sie die geschätzten Token in die Tabelle in Schritt 7 ein und
   summieren Sie auf.

## Erfolgskriterien

- [ ] `temp/tidy_fs_tool/[TS]/` existiert und enthält alle Quelldateien.
- [ ] Vergleich meldet `complete: true` und `missing_entry_count: 0`.
- [ ] `temp/tidy_report.md` existiert und ist vollständig ausgefüllt.

## Hinweise

- `fs_tool` benötigt `--yes` für Änderungen; ohne `--yes` wird nur validiert.
- `fs_tool` unterstützt `--dry-run` zur Vorschau von Änderungen.
- Nicht gleichzeitig an der Quelle oder am Ziel schreiben, während der
  Vergleich läuft (Inventare sind Momentaufnahmen, keine Dateisystem-Sperren).
