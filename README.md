# LAS to 3D Tiles Converter

Convert LAS point cloud files to Cesium 3D Tiles format using a Dockerized implementation of [**gocesiumtiler**](https://github.com/mfbonfigli/gocesiumtiler).

This repository provides:

- 🐳 **Docker container** with gocesiumtiler v2.0.1 built from source
- 🌐 **Web viewer** for testing conversion results locally
- 🔬 **Galaxy tool integration** for workflow automation

## Features

- ✅ **High Performance** - 5M+ points/second processing speed
- ✅ **Universal CRS Support** - Any EPSG code via PROJ 9.5.0
- ✅ **Modern 3D Tiles** - v1.1 GLB format output
- ✅ **Multi-file Support** - Merge multiple LAS files into a single tileset
- ⚠️ **Use LAS files** - LAZ (compressed) format currently not supported

## About

This is a containerized wrapper around [gocesiumtiler](https://github.com/mfbonfigli/gocesiumtiler) by Matteo Ferrabone Bonfigli, providing an easy-to-use Docker interface and optional Galaxy integration for converting LAS point clouds to Cesium 3D Tiles format

## Quick Start

### 1. Build the Docker Container

```bash
docker build -t las-to-3dtiles .
```

### 2. Convert Your LAS File

```bash
# Basic conversion (auto-detected CRS, default quality)
docker run --rm \
  -v ./data/input:/input \
  -v ./data/output:/output \
  las-to-3dtiles file \
  --out /output/tileset \
  /input/your-file.las

# With all parameters explicit
docker run --rm \
  -v ./data/input:/input \
  -v ./data/output:/output \
  las-to-3dtiles file \
  --out /output/tileset \
  --crs 32632 \
  --resolution 20 \
  --depth 10 \
  --min-points-per-tile 5000 \
  /input/your-file.las

# Convert multiple files into a single combined tileset
docker run --rm \
  -v ./data/input:/input \
  -v ./data/output:/output \
  las-to-3dtiles folder \
  --out /output/tileset \
  /input
```

**📁 Note on multiple files**: The `folder` command merges all LAS files in the input directory into a **single tileset**. This is ideal for large datasets that have been split into chunks. All files should represent parts of the same overall dataset and use the same CRS.

### 3. View Your 3D Tiles (Local Testing)

```bash
# Start the local web viewer
python viewer/serve.py

# Open in browser: http://localhost:8000/viewer/
```

The viewer is a simple evaluation tool providing:

- 🌍 Interactive 3D visualization with CesiumJS
- 📊 Auto-discovery of tilesets in `data/output/`
- 🎨 Adjustable point size and debug bounding volumes
- 🔍 Support for both PNTS (1.0) and glTF (1.1) formats

**Viewer Controls:**

- Left drag: Rotate | Right drag: Pan | Wheel: Zoom | F key: Fly to tileset

**Change Port:** Edit `PORT` variable in `viewer/serve.py` (default: 8000)

**Troubleshooting:** If the tileset doesn't load, check that:

- Server is running and accessible at `http://localhost:8000/viewer/`
- Output directory contains `tileset.json` and tile files
- Browser console (F12) for any error messages

## Command Reference

### Basic Commands

| Command | Description |
|---------|-------------|
| `file -o <output> <input>` | Convert single LAS file |
| `folder -o <output> <input-dir>` | Convert all LAS files in directory |
| `--help` | Show detailed help |

### Parameters

**How it works:** Points aren't deleted randomly. Space is divided into a 3D grid, keeping the point closest to each cell center at each LOD level. Other points become candidates for finer detail levels.

| Parameter | Default | Description | When to Adjust |
|-----------|---------|-------------|----------------|
| `-o, --out` | Required | Output directory for tileset | - |
| `--crs, --epsg` | Auto-detect | Input CRS (EPSG:#### format). Auto-detected from LAS metadata (GeoTIFF keys, WKT, PROJ strings). Specify manually if detection fails. | Specify when auto-detection fails |
| `--resolution` | 20 | Grid cell size in meters for spatial sampling | **Lower (5-10)**: Urban, small datasets, fine detail / **Higher (50-100)**: Large terrain, forests, quick previews |
| `--depth` | 10 | Maximum tree subdivision levels | **More (12-15)**: Very large datasets, smooth zoom transitions / **Less (6-8)**: Small datasets, faster conversion |
| `--min-points-per-tile` | 5000 | Minimum points before creating a tile | **Fewer (1000-3000)**: Smoother LOD, high quality / **More (8000-15000)**: Fewer HTTP requests, faster load |

### Common Presets

| Use Case | Resolution | Depth | Min Points | Notes |
|----------|------------|-------|------------|-------|
| **Default (balanced)** | 20 | 10 | 5000 | Good for most datasets |
| **Fast preview** | 50 | 8 | 10000 | Quick conversion, lower quality |
| **High quality** | 5 | 12 | 1000 | Urban models, fine detail |
| **Large datasets** | 20 | 12 | 5000 | Better progressive loading |
| **Memory constrained** | 40 | 8 | 8000 | Lower memory usage |

---

## 🔬 Galaxy Integration

This tool can be integrated into [Galaxy](https://galaxyproject.org/) workflow systems for automated point cloud processing in research pipelines.

### Quick Overview

**What is Galaxy?** An open-source platform for data-intensive research providing web-based interfaces, workflow automation, and reproducible analysis.

**Key Differences from Direct Docker Usage:**

- 🖥️ Web browser interface instead of command-line
- 🔄 Built-in workflow and batch processing
- ❌ Viewer not included (download tilesets and host externally)
- 📦 Uses same Docker container: `ghcr.io/3dtrees-earth/las-to-3dtiles:latest`

### Installation Options

**Quick Start:**

```bash
cd .galaxy
pip install planemo
planemo serve las_to_3dtiles.xml    # Launch local Galaxy for testing
```

**For Production:** Install in existing Galaxy, or publish to Tool Shed.

### 📖 Full Galaxy Documentation

All Galaxy-related files and comprehensive documentation are in **`.galaxy/`**:

- **[.galaxy/README.md](.galaxy/README.md)** - Complete setup guide, parameters, testing, troubleshooting
- **[.galaxy/GALAXY_INTEGRATION.md](.galaxy/GALAXY_INTEGRATION.md)** - Manual installation and Tool Shed publishing
- **[.galaxy/PLANEMO.md](.galaxy/PLANEMO.md)** - Testing and CI/CD integration

**Tool Files:** `las_to_3dtiles.xml`, `datatypes_conf.xml`, `.shed.yml`, `test-data/`

**External Resources:**

- Galaxy Project: <https://galaxyproject.org/>
- Tool Development: <https://planemo.readthedocs.io/>
- Tool Shed: <https://toolshed.g2.bx.psu.edu/>

---

## Version Information

- **gocesiumtiler**: v2.0.1 (built from source)
- **3D Tiles**: v1.1 GLB format
- **PROJ**: v9.5.0 (universal CRS support)

## Citation

If you use this tool, please cite the original gocesiumtiler:

```bibtex
@misc{gocesiumtiler2024,
  title = {gocesiumtiler: A tool for massive 3D pointclouds conversion to Cesium 3DTiles},
  author = {Matteo Ferrabone Bonfigli},
  year = {2024},
  url = {https://github.com/mfbonfigli/gocesiumtiler},
  note = {Version 2.0.1}
}
```

````
