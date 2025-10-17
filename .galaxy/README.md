# LAS to 3D Tiles Converter for Galaxy

A Galaxy tool for converting LAS/LAZ point cloud files to Cesium 3D Tiles format.

## About

This Galaxy tool wraps [gocesiumtiler](https://github.com/mfbonfigli/gocesiumtiler) by **Massimo Federico Bonfigli** to convert point cloud data into web-ready 3D tiles optimized for visualization with CesiumJS and other 3D Tiles-compatible viewers.

### Key Features

* **Input formats:** LAS and LAZ (automatically decompressed)
* **Output format:** Cesium 3D Tiles v1.1 (GLB format)
* **Performance:** 5M+ points/second processing speed
* **CRS support:** Universal coordinate system support via PROJ 9.5.0
* **Automatic CRS detection** from LAS file metadata

## Installation

This tool is available in the Galaxy ToolShed:

* **Name:** `las_to_3dtiles`
* **Owner:** `3dtrees`
* **Category:** Geospatial

Install via Galaxy Admin → Install and Uninstall → Search ToolShed

## Tool Documentation

Full user documentation is embedded in the Galaxy tool XML file and displayed in the Galaxy interface. Key parameters:

* **Input CRS:** Override auto-detected coordinate system (EPSG code)
* **Grid Resolution:** Spatial sampling density (5-100m)
* **Tree Depth:** Octree subdivision levels (4-20)
* **Minimum Points per Tile:** Tile creation threshold (100-50000)

See the tool's help section in Galaxy for complete usage information and recommended settings.

## Development & Testing

### Testing with Planemo

```bash
# Install planemo
pip install planemo

# Test the tool
planemo test las_to_3dtiles.xml

# Serve locally
planemo serve las_to_3dtiles.xml
```

### Repository Structure

```text
.galaxy/
├── las_to_3dtiles.xml      # Galaxy tool wrapper
├── .shed.yml               # ToolShed metadata
├── datatypes_conf.xml      # Custom datatype definitions
├── test-data/              # Test datasets
│   └── test.las
└── README.md               # This file
```

## Citation

If you use this tool in your research, please cite:

```bibtex
@misc{gocesiumtiler2024,
  title = {gocesiumtiler: A Cesium Point Cloud tile generator written in golang},
  author = {Matteo Ferrabone Bonfigli},
  year = {2024},
  url = {https://github.com/mfbonfigli/gocesiumtiler},
  note = {Version 2.0.1}
}
```

## License

This Galaxy tool wrapper is developed by the 3D Trees Project. The underlying gocesiumtiler software is by Massimo Federico Bonfigli.

## Support

* **Issues:** <https://github.com/3dtrees-earth/tool_3dtiles/issues>
* **Documentation:** See tool help in Galaxy interface
