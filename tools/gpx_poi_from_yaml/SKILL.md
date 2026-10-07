---
name: yaml-to-gpx-pois
description: Turn YAML place records into GPX waypoints by geocoding each location with the geocoding MCP tool and writing it with gpx-kml-converter.
---

# YAML places to GPX POIs

Use this workflow when a user wants named places in a YAML file added as waypoints to a GPX file.

## Requirements

- The geocoding MCP server must be available and expose `get_coordinates`.
- `gpx-kml-converter` must be installed and support `--mode add-poi`.
- The user must identify the input YAML and the target GPX path. Ask which base GPX to use if it is not clear whether the output should contain only these POIs or preserve an existing track/waypoints.

## Workflow

1. Read the YAML and identify place records. Support a top-level list or lists nested under section keys. Each record should have a `name`; use `desc` as the waypoint description when present and `rating` as a one-to-five rating when present. Do not silently discard malformed records.
2. Establish geographic context for each name from an explicit location field, the user's request, or an unambiguous section name. If context is missing or a place name has multiple plausible matches, ask the user for context rather than selecting an arbitrary result.
3. For each place, call the geocoding MCP tool `get_coordinates` with the place name and geographic context in `location`. Request multiple candidates with `limit` when useful. Check that returned latitude and longitude are numeric and within -90..90 and -180..180, respectively, and that the result is the intended place and feature. A geocoder result may identify an approximate point, not an entrance or the ideal place to stand.
4. Before writing, review uncertain results with the user. Keep a clear record of which YAML entries have been geocoded and written; do not retry completed entries blindly because the CLI does not deduplicate waypoints.
5. Build the waypoint name from the YAML name. For an integer `rating` from 1 through 5, append that many Unicode stars separated by a space, for example `Spiaggia La Pelosa ★★★★★`. For a missing rating, leave the name unchanged. For an invalid rating, ask how to handle it; do not silently clamp or reinterpret it. Do not put the rating in `desc`.
6. Add each waypoint with `gpx-kml-converter --mode add-poi`, passing the returned `--lat` and `--lon`, the formatted `--name`, and `--desc` when present. Use `--sym Beach` for beaches when appropriate; do not invent elevation. Quote each value as a separate CLI argument, especially names and descriptions with spaces or punctuation.
7. Report the output path and any records that were skipped or need review. Do not claim completion for entries that were not written.

## Output safety

`add-poi` appends one waypoint at a time and does not detect duplicates. Without `--output`, the input GPX is modified in place. For a new POI-only file, use its intended `.gpx` path as the input; the CLI creates it when it does not exist. To preserve an existing GPX, make a working copy first and append to that copy. If processing is interrupted, inspect the file and resume only with entries that are still missing.

Use `--mode add-poi` to append one waypoint to a GPX file. The input must be a single
`.gpx` path; if it does not exist, a new GPX document is created. The waypoint is appended
even if an equivalent waypoint already exists. Latitude, longitude, and name are required;
description, symbol, and elevation are optional.

| Option | Description |
| --- | --- |
| `--lat` | Latitude in decimal degrees, from -90 to 90 |
| `--lon` | Longitude in decimal degrees, from -180 to 180 |
| `--name` | Waypoint name |
| `--desc` | Optional waypoint description |
| `--sym` | Optional waypoint symbol |
| `--ele` | Optional elevation in meters |

## Example

gpx-kml-converter --mode add-poi --lat 48.8584 --lon 2.2945 --name "Eiffel Tower" --desc "A iconic landmark in Paris." --sym Landmark --ele 330 new-pois.gpx
