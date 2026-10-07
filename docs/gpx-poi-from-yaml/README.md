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

# Workflow

## 1. Prepare and geocode the YAML

e.g. Ask ChatGPT for a place list

For example:

> I'm planning a family holiday in Sardinia. Suggest around 40 places to visit, including towns, scenic spots, hikes, and historical sites. Do not include beaches. Return the list as YAML with each place's name, a short description, and a rating from 1 to 5.

Save the result as a `.yaml` file, for example `highlights.yaml`.

## 2. Use this YAML format

Each place needs a `name`. Include a short `desc` and a `rating` from 1 to 5:

```yaml
- name: "Su Nuraxi di Barumini"
  desc: "A remarkable Bronze Age archaeological site."
  rating: 5
- name: "Gola di Gorropu"
  desc: "A dramatic canyon with hiking trails."
  rating: 4
```

Use place names that are easy to recognize on a map. Keep the list in the region you asked ChatGPT about; the agent uses that context to find the places.

## 3. Ask your IDE agent to create the GPX file

For example:

> Convert `highlights.yaml` into a GPX file named `highlights.gpx`. Use the skill `tools/gpx_poi_from_yaml/SKILL.md` and the geocoding MCP tool `get_coordinates`. The places are in Sardinia, Italy.

Review the resulting places on a map. Ratings are shown as stars added to each waypoint name. If a place is ambiguous or appears in the wrong location, clarify it with the agent before using the GPX file.
