# Galaxy Tool Integration - Complete Guide

This directory contains all files needed to integrate the LAS to 3D Tiles converter into Galaxy.

> **📖 Note:** This is the comprehensive Galaxy integration guide. For general tool usage, see the [main README](../README.md).

## 📁 Files in This Directory

- **`las_to_3dtiles.xml`** - Main Galaxy tool wrapper (tool interface, parameters, outputs)
- **`datatypes_conf.xml`** - Datatype definitions (LAS/LAZ and 3D Tiles formats)
- **`.shed.yml`** - Tool Shed publishing configuration
- **`test-data/`** - Test files directory (place `test.las` sample file here)

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Installation Methods](#-installation-methods)
- [Tool Configuration](#-tool-configuration)
- [Testing with Planemo](#-testing-with-planemo)
- [Container & Job Configuration](#-container--job-configuration)
- [Troubleshooting](#-troubleshooting)
- [CI/CD Integration](#-cicd-integration)

---

## � Quick Start

### 1. Test Locally with Planemo

```bash
# Install planemo
pip install planemo

# Lint the tool
planemo lint las_to_3dtiles.xml

# Add test data (create or copy a small LAS file)
# Place it in test-data/test.las

# Run tests
planemo test las_to_3dtiles.xml

# Serve in local Galaxy instance
planemo serve las_to_3dtiles.xml
```

### 2. Install in Galaxy (Manual)

```bash
# Copy tool to Galaxy tools directory
cp las_to_3dtiles.xml $GALAXY_ROOT/tools/geospatial/

# Merge datatypes into Galaxy config
# Edit $GALAXY_ROOT/config/datatypes_conf.xml and add entries from datatypes_conf.xml

# Add to toolbox
# Edit $GALAXY_ROOT/config/tool_conf.xml:
#   <section id="geospatial" name="Geospatial Tools">
#     <tool file="geospatial/las_to_3dtiles.xml" />
#   </section>

# Restart Galaxy
$GALAXY_ROOT/run.sh --daemon restart
```

### 3. Publish to Tool Shed

```bash
# Configure Tool Shed credentials (creates ~/.planemo.yml)
planemo config_init

# Upload to Test Tool Shed first
planemo shed_upload --shed_target testtoolshed

# After testing, upload to production Tool Shed
planemo shed_upload --shed_target toolshed
```

---

## 🛠️ Installation Methods

### Method 1: Planemo (Development & Testing)

**Best for:** Local testing, development, CI/CD

```bash
cd .galaxy
pip install planemo
planemo serve las_to_3dtiles.xml    # Launch local Galaxy
```

**Pros:** Quick setup, no Galaxy installation needed  
**Cons:** Temporary, not for production

### Method 2: Manual Installation (Production)

**Best for:** Existing Galaxy instances, full control

```bash
# 1. Copy tool to Galaxy tools directory
cp las_to_3dtiles.xml $GALAXY_ROOT/tools/geospatial/

# 2. Merge datatypes into Galaxy config
# Edit $GALAXY_ROOT/config/datatypes_conf.xml and add entries from datatypes_conf.xml

# 3. Register tool in toolbox
# Edit $GALAXY_ROOT/config/tool_conf.xml:
#   <section id="geospatial" name="Geospatial Tools">
#     <tool file="geospatial/las_to_3dtiles.xml" />
#   </section>

# 4. Restart Galaxy
$GALAXY_ROOT/run.sh --daemon restart
```

### Method 3: Tool Shed (Recommended for Distribution)

**Best for:** Sharing with community, automatic updates

```bash
planemo shed_upload --shed_target toolshed
```

**Pros:** Easy installation for users, version management  
**Cons:** Requires Tool Shed account, public repository

---

## 🔧 Tool Configuration

### What the Tool Does

The Galaxy tool wrapper:

1. Accepts LAS point cloud files as input
2. Runs `gocesiumtiler` in Docker container
3. Converts to Cesium 3D Tiles format
4. Outputs tileset.json and discovered tile files
5. Does **NOT** generate HTML viewer (viewer is only for this repo)

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| Input | File (LAS) | Required | Point cloud file to convert |
| CRS | Text (EPSG) | Auto-detect | Override coordinate system |
| Resolution | Integer | 20 | Grid cell size in meters (1-200) |
| Depth | Integer | 10 | Octree subdivision levels (4-20) |
| Min Points/Tile | Integer | 5000 | Tile creation threshold (100-50000) |

### Outputs

- **Tileset Metadata** (JSON): Main `tileset.json` file
- **Tile Files**: Additional 3D tile files (GLB format) discovered automatically

### Parameter Guidance

**How the conversion works:** Points aren't deleted randomly. Space is divided into a 3D grid, keeping the point closest to each cell center at each LOD level. Other points become candidates for finer detail levels.

| Use Case | Resolution | Depth | Min Points | Notes |
|----------|------------|-------|------------|-------|
| **Default (balanced)** | 20 | 10 | 5000 | Good for most datasets |
| **Fast preview** | 50 | 8 | 10000 | Quick conversion, lower quality |
| **High quality** | 5 | 12 | 1000 | Urban models, fine detail |
| **Large datasets** | 20 | 12 | 5000 | Better progressive loading |
| **Memory constrained** | 40 | 8 | 8000 | Lower memory usage |

**When to adjust parameters:**

- **Resolution**: Lower (5-10) for urban/fine detail; Higher (50-100) for terrain/quick previews
- **Depth**: More (12-15) for very large datasets; Less (6-8) for small datasets
- **Min Points/Tile**: Fewer (1000-3000) for smoother LOD; More (8000-15000) for faster loading

### Output Usage

**Important:** Galaxy tool does NOT include the HTML viewer (viewer is only in this repository).

After conversion in Galaxy:

1. Download the tileset files from Galaxy
2. Upload to a web server (Apache, Nginx, S3, etc.)
3. View with CesiumJS or other 3D Tiles viewers
4. Or use the viewer from this repository by placing files in `data/output/`

---

## 🧪 Testing with Planemo

### Test Data Setup

```bash
# Create test data directory
cd .galaxy
mkdir -p test-data

# Option 1: Copy sample from real data
cp /path/to/sample.las test-data/test.las

# Option 2: Generate synthetic test data
python << EOF
import laspy
import numpy as np

header = laspy.LasHeader(point_format=2, version="1.2")
header.offsets = [0, 0, 0]
header.scales = [0.01, 0.01, 0.01]

las = laspy.LasData(header)
las.x = np.random.rand(1000) * 100
las.y = np.random.rand(1000) * 100
las.z = np.random.rand(1000) * 10
las.red = np.random.randint(0, 65535, 1000)
las.green = np.random.randint(0, 65535, 1000)
las.blue = np.random.randint(0, 65535, 1000)

las.write("test-data/test.las")
EOF

# Run tests
planemo test las_to_3dtiles.xml
```

### Creating Test Data with CRS

For comprehensive testing, generate a synthetic LAS file with proper CRS metadata:

```python
import laspy
import numpy as np

# Create minimal LAS file with CRS
header = laspy.LasHeader(point_format=2, version="1.2")
header.offsets = [500000, 5500000, 0]  # Typical UTM offsets
header.scales = [0.01, 0.01, 0.01]

# Set CRS to EPSG:32632 (UTM Zone 32N)
from laspy.vlrs.known import WktCoordinateSystemVlr
wkt = """PROJCS["WGS 84 / UTM zone 32N",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",9],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1]]"""
header.vlrs.append(WktCoordinateSystemVlr(wkt))

# Generate 1000 random points in a 100x100x10m area
las = laspy.LasData(header)
las.x = np.random.rand(1000) * 100 + 500000
las.y = np.random.rand(1000) * 100 + 5500000
las.z = np.random.rand(1000) * 10
las.red = np.random.randint(0, 65535, 1000)
las.green = np.random.randint(0, 65535, 1000)
las.blue = np.random.randint(0, 65535, 1000)

# Save to test-data directory
las.write("test-data/test.las")
print("Created test.las with 1000 points and EPSG:32632 CRS")
```

**Note:** Keep test files small (<50MB) for fast testing. The synthetic data above creates a ~30KB file suitable for CI/CD.

**Run tests:**

```bash
cd .galaxy
planemo lint las_to_3dtiles.xml                                      # Check tool syntax
planemo test las_to_3dtiles.xml                                      # Run tests
planemo test --test_output test_results.html las_to_3dtiles.xml     # Generate HTML report
```

---

## 🐳 Container & Job Configuration

The tool uses the pre-built Docker container:

```
ghcr.io/3dtrees-earth/las-to-3dtiles:latest
```

### Container Contents

- gocesiumtiler v2.0.1 (built from source)
- PROJ 9.5.0 (universal CRS support)
- All required dependencies

### Galaxy Requirements

- Docker or Singularity support enabled
- Container auto-pulling configured
- Network access to GitHub Container Registry

### Job Configuration for Large Datasets

For processing large point clouds, configure job resources:

```yaml
# job_conf.yml
tools:
  - id: 3dtrees_las_to_3dtiles
    environment:
      GALAXY_MEMORY_MB: 16000
      GALAXY_SLOTS: 8
    scheduling:
      require: mem >= 16GB
```

**Memory guidelines:**

- Small datasets (<100M points): 4-8 GB
- Medium datasets (100M-500M points): 8-16 GB
- Large datasets (>500M points): 16-32 GB

---

## 🔍 Troubleshooting

### Common Issues

**"Container not found"**

- Ensure Docker/Singularity is configured in Galaxy
- Check network access to ghcr.io
- Verify container resolver configuration

**"Format 'las' not recognized"**

- Datatypes not registered properly
- Merge `datatypes_conf.xml` into Galaxy config
- Restart Galaxy after datatype changes

**"Job fails with memory error"**

- Increase memory allocation in `job_conf.yml`
- Reduce resolution or depth parameters
- Use smaller input files for testing

**"CRS not detected"**

- LAS file may lack CRS metadata
- Manually specify EPSG code in tool form
- Check LAS file with `lasinfo` or `pdal info`
- Verify CRS in Docker: `docker run --rm -v ./data:/data las-to-3dtiles file --help /data/input.las`

**"Output files not collected"**

- Verify `discover_datasets` pattern in XML
- Check output directory permissions
- Ensure tileset.json is generated
- Look for GLB files in subdirectories

---

## � CI/CD Integration

### GitHub Actions Example

Add to `.github/workflows/galaxy-tool-test.yml`:

```yaml
name: Galaxy Tool Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install Planemo
        run: pip install planemo
      
      - name: Lint Tool
        run: |
          cd .galaxy
          planemo lint las_to_3dtiles.xml
      
      - name: Run Tests
        run: |
          cd .galaxy
          planemo test las_to_3dtiles.xml
```

### Planemo Configuration

Create `.planemo.yml` in repository root for Tool Shed credentials:

```yaml
## Planemo Configuration File
sheds:
  toolshed:
    key: YOUR_API_KEY
    email: your-email@example.com
  testtoolshed:
    key: YOUR_TEST_API_KEY
    email: your-email@example.com

## Test configuration
test_output: test_output.html
docker: true
```

---

## 📚 Additional Resources

**External Documentation:**

- **Galaxy Project**: <https://galaxyproject.org/>
- **Tool Development (Planemo)**: <https://planemo.readthedocs.io/>
- **Tool XML Schema**: <https://docs.galaxyproject.org/en/master/dev/schema.html>
- **IUC Best Practices**: <https://galaxy-iuc-standards.readthedocs.io/>
- **Tool Shed**: <https://toolshed.g2.bx.psu.edu/>
- **gocesiumtiler**: <https://github.com/mfbonfigli/gocesiumtiler>

**Format Specifications:**

- **Cesium 3D Tiles**: <https://github.com/CesiumGS/3d-tiles>
- **LAS Specification**: <https://www.asprs.org/divisions-committees/lidar-division/laser-las-file-format-exchange-activities>
- **PROJ (CRS Library)**: <https://proj.org/>

---

## 📝 Pre-Deployment Checklist

Before deploying to Galaxy, verify:

**Tool Configuration:**

- [ ] `las_to_3dtiles.xml` - Tool wrapper is complete and valid
- [ ] `datatypes_conf.xml` - Datatypes are defined for LAS/LAZ and 3D Tiles
- [ ] `.shed.yml` - Tool Shed metadata is configured (if publishing)

**Testing:**

- [ ] `test-data/test.las` - Test data is available and <50MB
- [ ] `planemo lint las_to_3dtiles.xml` - Passes with no errors
- [ ] `planemo test las_to_3dtiles.xml` - All tests pass
- [ ] Container is accessible: `docker pull ghcr.io/3dtrees-earth/las-to-3dtiles:latest`

**Galaxy Integration:**

- [ ] Datatypes merged into Galaxy config
- [ ] Tool registered in toolbox
- [ ] Docker/Singularity configured
- [ ] Network access to ghcr.io verified
- [ ] Job resources configured for large files (if needed)

**Documentation:**

- [ ] README.md is up to date
- [ ] Installation instructions tested
- [ ] Troubleshooting section is comprehensive
- [ ] Links to external resources are valid

---

*Last updated: January 2025*
