# LAS to 3D Tiles Converter

Docker container for converting LAS/LAZ point cloud files to Cesium 3D Tiles format using [gocesiumtiler](https://github.com/mfbonfigli/gocesiumtiler).

## Quick Start

### Using Docker

```bash
# Pull the latest container
docker pull ghcr.io/3dtrees-earth/tool_3dtiles:latest

# Convert a single LAS file
docker run --rm \
  -v /path/to/data:/input \
  -v /path/to/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  gocesiumtiler file --out /output/tileset /input/yourfile.las

# Convert LAZ (automatically decompressed)
docker run --rm \
  -v /path/to/data:/input \
  -v /path/to/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  gocesiumtiler file --out /output/tileset /input/yourfile.laz
```

### Using the Wrapper Script

The container includes a wrapper script that automatically generates output directories and handles LAZ conversion:

```bash
# Auto-named output directory (based on input filename)
docker run --rm \
  -v /path/to/data:/input \
  -v /path/to/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  /usr/local/bin/converter-wrapper.sh file /input/yourfile.las

# Batch process multiple files
docker run --rm \
  -v /path/to/data:/input \
  -v /path/to/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  /usr/local/bin/converter-wrapper.sh batch /input
```

## Parameters

### Essential Options

```bash
--out <dir>              # Output directory for tileset
--crs <EPSG>            # Input CRS (e.g., EPSG:32632)
--version <ver>         # 3D Tiles version (1.0 or 1.1)
```

### Quality & Performance

```bash
--resolution <meters>           # Grid cell size (default: 20)
                               # Lower (5-10): urban/detailed
                               # Higher (50-100): terrain/preview

--depth <levels>               # Max tree depth (default: 10)
                              # More (12-15): smoother zoom
                              # Less (6-8): faster conversion

--min-points-per-tile <n>     # Min points per tile (default: 5000)
                              # Fewer (1000-3000): more tiles, smoother LOD
                              # More (8000-15000): fewer files, faster load
```

## Examples

### High Quality Urban Scan

```bash
docker run --rm \
  -v $(pwd)/data:/input \
  -v $(pwd)/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  gocesiumtiler file \
  --out /output/urban_tileset \
  --crs EPSG:32632 \
  --version 1.1 \
  --resolution 5 \
  --depth 12 \
  --min-points-per-tile 1000 \
  /input/urban_scan.las
```

### Fast Preview (Large Terrain)

```bash
docker run --rm \
  -v $(pwd)/data:/input \
  -v $(pwd)/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  gocesiumtiler file \
  --out /output/terrain_preview \
  --version 1.1 \
  --resolution 50 \
  --depth 8 \
  --min-points-per-tile 10000 \
  /input/terrain.laz
```

### Batch Processing

```bash
# Process all LAS/LAZ files in a directory
docker run --rm \
  -v $(pwd)/input:/input \
  -v $(pwd)/output:/output \
  ghcr.io/3dtrees-earth/tool_3dtiles:latest \
  /usr/local/bin/converter-wrapper.sh batch \
  --resolution 20 \
  --depth 10 \
  /input
```

## Building the Container

```bash
# Clone the repository
git clone https://github.com/3dtrees-earth/tool_3dtiles.git
cd tool_3dtiles

# Build locally
docker build -t tool_3dtiles:local .

# Use local build
docker run --rm \
  -v $(pwd)/data:/input \
  -v $(pwd)/output:/output \
  tool_3dtiles:local \
  gocesiumtiler file --out /output/tileset /input/test.las
```

## Galaxy Tool

This repository also contains a Galaxy tool wrapper for use in Galaxy workflows. See `.galaxy/README.md` for Galaxy-specific documentation.

* **ToolShed:** `las_to_3dtiles` by `3dtrees`
* **Category:** Geospatial

## Output Format

The tool generates a complete 3D Tileset directory:

* `tileset.json` - Main metadata file
* `*.glb` - Binary 3D Tiles in octree structure
* Ready for web hosting with CesiumJS

### Viewing Your Tiles

See the [CesiumJS quickstart](https://cesium.com/learn/cesiumjs-learn/cesiumjs-quickstart/) or [hosting 3D content guide](https://cesium.com/on-prem/hosting-3d-content/) for visualization options.

## Technical Details

* **Engine:** gocesiumtiler v2.0.1
* **3D Tiles Version:** 1.1 (GLB format)
* **CRS Support:** Universal via PROJ 9.5.0
* **Performance:** 5M+ points/second
* **LAZ Support:** Automatic decompression via LAStools

## License

This Docker container and Galaxy tool wrapper are developed by the 3D Trees Project. The underlying gocesiumtiler software is by Massimo Federico Bonfigli.

## Citation

```bibtex
@misc{gocesiumtiler2024,
  title = {gocesiumtiler: A Cesium Point Cloud tile generator written in golang},
  author = {Matteo Ferrabone Bonfigli},
  year = {2024},
  url = {https://github.com/mfbonfigli/gocesiumtiler},
  note = {Version 2.0.1}
}
```

## Support

* **Issues:** <https://github.com/3dtrees-earth/tool_3dtiles/issues>
* **Galaxy Documentation:** See `.galaxy/README.md`
