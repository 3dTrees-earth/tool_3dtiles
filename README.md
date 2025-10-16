# Overview

This tool converts LAS/LAZ point cloud files to Cesium 3D Tiles format using [gocesiumtiler](https://github.com/mfbonfigli/gocesiumtiler) by **Massimo Federico Bonfigli**, creating an interactive web-based visualization optimized for large point cloud datasets.

---

## Outputs

The tool generates a complete 3D Tileset directory containing:

* **tileset.json** - Main metadata file describing tile hierarchy and geometric error
* **GLB tiles** - Binary 3D Tiles (Cesium 3D Tiles v1.1 format) organized in octree structure
* **Complete directory** - Full tileset folder ready for web hosting or further processing

The tileset directory output can be downloaded as a collection and hosted on any web server for visualization with CesiumJS or other 3D Tiles-compatible viewers. See the [CesiumJS quickstart](https://cesium.com/learn/cesiumjs-learn/cesiumjs-quickstart/) for a general introduction. For guidance on hosting 3D Tiles on-premises (serving local files), see <https://cesium.com/on-prem/hosting-3d-content/>.

---

## Input

### Supported Formats

* LAS point cloud files (uncompressed)
* LAZ point cloud files (compressed - automatically decompressed during processing)
* Coordinate Reference System (CRS) automatically detected from file metadata
* Optimized for large datasets

---

## Parameters

### Input CRS (Optional)

Override auto-detected coordinate reference system.

* **Format:** EPSG code (e.g., ``EPSG:32632`` or ``32632``)
* **Default:** Empty (auto-detect from LAS metadata)
* **Use when:** LAS file has incorrect/missing CRS information

### Grid Resolution (meters)

Controls spatial sampling density for level-of-detail generation.

* **Lower (5-10m):** Urban areas, architectural models, fine detail preservation
* **Default (20m):** Balanced quality for most datasets  
* **Higher (50-100m):** Large terrain, forests, quick preview conversions

### Tree Depth

Maximum octree subdivision levels for progressive detail loading.

* **Lower (6-8):** Small datasets, faster conversion, fewer tiles
* **Default (10):** Balanced for most use cases
* **Higher (12-15):** Very large datasets, smoother zoom transitions

### Minimum Points per Tile

Threshold for tile creation - affects LOD quality and file count.

* **Fewer (1000-3000):** Smoother level-of-detail transitions, more tiles
* **Default (5000):** Balanced performance
* **More (8000-15000):** Fewer HTTP requests, faster initial load

---

## Recommended Use

**Default (Balanced)**

* Resolution: 20m
* Depth: 10
* Min Points: 5000
* *Good for most datasets, balanced quality and performance*

**Fast Preview**

* Resolution: 50m
* Depth: 8
* Min Points: 10000
* *Quick conversion for testing, lower quality*

**High Quality Urban**

* Resolution: 5m
* Depth: 12
* Min Points: 1000
* *Architectural models, detailed city scans*

**Large Terrain/Forest**

* Resolution: 20m
* Depth: 12
* Min Points: 5000
* *Landscapes, large study areas*

---

## Technical Details

**Engine:** gocesiumtiler v2.0.1
**3D Tiles Version:** 1.1 (GLB format)
**CRS Support:** Universal via PROJ 9.5.0
**Performance:** 5M+ points/second
**Output Format:** Cesium 3D Tiles with octree spatial index
