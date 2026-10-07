# Creating GPX POIs from YAML place lists

This guide describes a repeatable workflow for turning named places in a YAML file into GPX waypoints:

1. Read each place's name, description, and optional rating.
2. Resolve the place with the geocoding MCP server's `get_coordinates` tool.
3. Review ambiguous or approximate results.
4. Add each waypoint with `gpx-kml-converter --mode add-poi`.

The agent workflow is documented in [`tools/gpx_poi_from_yaml/SKILL.md`](../../tools/gpx_poi_from_yaml/SKILL.md).

## Prerequisites

- An MCP client that supports local stdio MCP servers.
- `uv` with `uvx` available.
- `gpx-kml-converter` installed and on `PATH`. For installation and CLI details, see [Processing GPX/KML files](../ubuntu-linux-automations/README_process_gpx_kml.md).
- A YAML file containing place records with at least a `name`. The workflow uses `desc` as a description and an optional integer `rating` from 1 through 5.

## Configure the geocoding MCP server

The [geocode-mcp package](https://mcpservers.org/de/servers/X-McKay/geocode-mcp) can be launched with `uvx`. Configure the MCP client with:

```json
{
  "mcpServers": {
    "geocoding": {
      "command": "uvx",
      "args": ["--with", "mcp<2", "geocode-mcp"]
    }
  }
}
```

The `mcp<2` constraint is a compatibility workaround for the reported startup error `AttributeError: 'Server' object has no attribute 'list_tools'`: `geocode-mcp` may otherwise resolve an MCP SDK version whose API is incompatible with the server code. Restart the MCP client after changing the configuration and confirm that `get_coordinates` is available.

`uvx` runs the package in its own isolated environment. Installing `geocode-mcp` with `uv pip install` in a different environment does not control the dependencies used by this `uvx` configuration. If installing into a managed environment instead, apply the same `mcp<2` constraint there. Revisit the pin if the package is updated to support newer MCP SDK versions.

## Prepare and geocode the YAML

For example, a list can be nested under a descriptive section key:

```yaml
sardinia_beaches:
  - name: "Spiaggia La Pelosa"
    desc: "White sand and shallow turquoise water."
    rating: 5
```

Use geographic context in each geocoding request, for example `Spiaggia La Pelosa, Sardinia, Italy`. The context may come from the user's instructions, a location field, or a clearly informative section name. Do not rely on a place name alone when multiple matches are plausible.

Call `get_coordinates` once per place, or request several candidates when the result is uncertain. Check the returned coordinates are within valid latitude/longitude ranges and verify the match corresponds to the named place in the expected region. Geocoding can return an approximate feature point; it does not guarantee a beach entrance, parking area, or the best point for navigation. Ask the user to resolve material ambiguity instead of silently choosing a candidate.

The `rating` is represented as stars appended to the waypoint name: `Spiaggia La Pelosa ★★★★★` for rating 5, down to one star for rating 1. Missing ratings leave names unchanged. Invalid ratings should be corrected or explicitly resolved; the converter has no native rating field.

## Write the GPX waypoints

Create a new file containing only the POIs by passing a not-yet-existing `.gpx` path as the input:

```bash
gpx-kml-converter --mode add-poi \
  --lat 40.9631 --lon 8.1586 \
  --name "Spiaggia La Pelosa ★★★★★" \
  --desc "White sand and shallow turquoise water." \
  --sym Beach sardinia-beaches.gpx
```

Repeat the command for each place, using the same output path. The first call creates the GPX file and subsequent calls append waypoints to it. The sample coordinates are illustrative only; use the results returned for the actual places.

To add POIs to an existing GPX without changing the original, first make a working copy and use that copy as the input for every `add-poi` call:

```bash
cp holiday.gpx holiday-with-pois.gpx
gpx-kml-converter --mode add-poi \
  --lat 40.9631 --lon 8.1586 \
  --name "Spiaggia La Pelosa ★★★★★" \
  --desc "White sand and shallow turquoise water." \
  --sym Beach holiday-with-pois.gpx
```

Do not provide elevation unless it is known and appropriate; it is optional. Use the converter's `--output` option only when intentionally writing to a separate destination, and consult the GPX CLI guide for its exact behavior.

## Limitations and safe operation

- Each command appends one waypoint. The converter does not deduplicate equivalent locations, so rerunning completed commands creates duplicates.
- Without an output destination, the input GPX is modified in place. Work on a copy if the original must be preserved.
- A sequence of commands may leave a partially populated file if interrupted. Track completed entries and inspect the output before resuming.
- Names and descriptions are user data. Pass them as properly quoted, separate CLI arguments; avoid constructing an unquoted shell command from YAML values.
- The geocoding MCP requires network access. Review the MCP/geocoding provider's terms and avoid sending sensitive location queries.
