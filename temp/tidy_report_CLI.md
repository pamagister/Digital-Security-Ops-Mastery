# Sortierbericht: temp/Segeln_JTC → temp/tidy_Segeln_JTC_fs_tool

**Datum:** 2026-11-03 23:41:43  
**Werkzeug:** fs_tool (CLI `fs-tool`, Paket `tools/fs_tool`)  
**Quelle:** temp/Segeln_JTC/  
**Ziel:** temp/tidy_Segeln_JTC_fs_tool/  
**Zeitstempel (TS):** 20261103_234143

## Zusammenfassung

| Kennzahl | Wert |
|---|---|
| Quelldateien insgesamt | 92 |
| Erfolgreich kopiert | 92 |
| Fehlgeschlagen | 0 |
| Vergleich vollständig | ja |
| Fehlende Einträge nach Vergleich | 0 |
| Quell-Inventar `complete` | true |
| Quell-Inventar `tree_sha256` | cfa09f88f1182ec28007fbf8884dc537a7ae05728ae2157f32d92032d9094e88 |
| Vergleich `complete` | true |
| Vergleich `missing_entry_count` | 0 |

## Zielordnerstruktur und Gruppierung (logisch, nach Inhalt)

Die 92 Quelldateien wurden in 8 inhaltlich zusammenhängende Gruppen kopiert (Datum, Größe und Dateityp waren nicht das Hauptkriterium):

| Zielordner | Dateien | Inhalt |
|---|---:|---|
| `01_Crewlisten/` | 12 | Crewlisten (authority/skipper/charter/partner, Sardinien & Schwedische Schären, Korfu, Sardinien & Korsika) |
| `02_Skipper-Verträge/` | 14 | Skipper-Verträge (Dänische Südsee, Ibiza & Formentera, Kykladen, Mallorca) |
| `03_Skipper-Views_und_Routen/` | 20 | Skipper-Views, Routenbilder, Track-Dateien (Dänische Südsee, Dodekanes-Kos, JTC-Skipper-View, Stockholm) |
| `04_Checklisten/` | 4 | Checklisten |
| `05_Einkaufslisten/` | 4 | Einkaufslisten (Mittelmeer, Kykladen) |
| `06_Infomaterial_und_Reisefuehrer/` | 32 | Infomaterial, Reiseführer, Inhaltsverzeichnis, Satellitenbilder (Balearen) |
| `07_Segelpraxis_Aufhaengen/` | 2 | Aufhängen im Boot / an Bord |
| `08_Nachweise_und_Dokumente/` | 4 | Seemeilennachweis, Crew-Einweisung, Unterschrift, Kontakte Stockholm |
| **Gesamt** | **92** | |

## Verifikation (Schritt 6)

`fs-tool compare temp/Segeln_JTC temp/tidy_Segeln_JTC_fs_tool`

- Exit-Code: 0
- `complete`: true
- `source_entry_count`: 92
- `matched_entry_count`: 92
- `missing_entry_count`: 0
- `errors`: [], `unsupported_entries`: []

Alle 92 Quelldateien sind nach Inhalt (SHA-256) unverändert im Ziel vorhanden. Das Ziel wurde durch den Inhalts-Vergleich verifiziert.

## Erzeugte Dateien im Ziel

- `inventory_source.json` – Quell-Inventar (Schritt 2)
- `copy_manifest.tsv` – Kopier-Manifest (Quelle → Kategorie)
- `compare_result.json` – Vergleichsergebnis (Schritt 6)
- die 8 Kategorieordner mit den 92 kopierten Dateien

## Schritt 8: Token-Verbrauch (Schätzung)

Faustregel: ca. 4 Zeichen ≈ 1 Token (Deutsch/Englisch gemischt). Die tatsächlichen Werte hängen von der LLM-Oberfläche ab.

| Tool-Aufruf | Eingabe (Zeichen) | Ausgabe (Zeichen) | Eingabe ≈ Token | Ausgabe ≈ Token |
|---|---:|---:|---:|---:|
| `fs-tool inventory temp/Segeln_JTC` | ~40 | 19 640 (inventory_source.json) | ~10 | ~4 910 |
| `fs-tool copy --yes` × 92 | ~120 je Aufruf | ~200 je Aufruf | ~2 760 | ~4 600 |
| `fs-tool compare …` | ~50 | 178 (compare_result.json) | ~13 | ~45 |
| `fs-tool mkdir --yes` × 8 | ~50 je Aufruf | ~90 je Aufruf | ~100 | ~180 |
| `fs-tool move --yes` × 4 | ~110 je Aufruf | ~150 je Aufruf | ~110 | ~150 |
| Bericht schreiben (tidy_report.md) | — | ~2 000 | — | ~500 |
| **Summe (geschätzt)** | | | **~3 093** | **~10 385** |



## Erfolgskriterien

- [x] `temp/tidy_Segeln_JTC_fs_tool/` existiert und enthält alle 92 Quelldateien.
- [x] Vergleich meldet `complete: true` und `missing_entry_count: 0`.
- [x] `temp/tidy_report.md` existiert und ist vollständig ausgefüllt.
