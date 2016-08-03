windows-builds
===================

[![Build status](https://ci.appveyor.com/api/projects/status/5bgyk71sbsg58n77?svg=true)](https://ci.appveyor.com/project/Mapbox/windows-builds)
[![Build Status](https://travis-ci.org/mapbox/windows-builds.svg?branch=master)](https://travis-ci.org/mapbox/windows-builds)

**Things are moving fast and sometimes break.
If something doesn't work for you, please [open an issue](https://github.com/mapbox/windows-builds/issues/new).**

Windows build scripts mainly targeting:
* mapnik and its dependencies
* C++11 build of node
* node-mapnik

Other supported software:
* node-gdal
* osmium: libosmium, node-osmium, osmium-tool
* osrm

## Requirements

 - __64bit__ operating system (W7, 8, 8.1, 10, Server 2012)
 - [Visual Studio 2015](https://www.visualstudio.com/en-us/downloads/download-visual-studio-vs.aspx), **No earlier versions suppported, C++11 support needed!**
   Note* - Uninstall update 3 from VS 2015 if you have installed with update3. This causes [the issue in compilation] (https://github.com/mapbox/windows-builds/issues/92)
 - [Python 2.7 32 bit](https://www.python.org/downloads/windows/) installed into `C:\Python27`
 - [git](https://msysgit.github.io/) installed into `C:\Program Files (x86)\Git`

### Recommendations:

 - If you are using AWS, then [this `ami-6f2cf804` in `us-east-1`](https://aws.amazon.com/marketplace/ordering?productId=6880e80b-b23d-4689-877e-02e40bdfe170&ref_=dtl_psb_continue&region=us-east-1) is a good starting point
 - Then install `Visual Studio Express 2015 for Windows Desktop` from https://www.visualstudio.com/en-us/downloads/download-visual-studio-vs.aspx ([direct download](http://download.microsoft.com/download/D/E/5/DE5263E9-A58D-469A-BA16-14786E2E2B1C/wdexpress_full.exe))

## System Setup

Install:

 - Python 2.7 32 bit
 - Git
 - Visual Studio VS2015

**When using your builds on machines that don't have Visual Studio installed you have to install the C++ runtime corresponding to the VS version that was used for building:**
* VS2015 runtime:
  * [x64](<https://mapbox.s3.amazonaws.com/windows-builds/visual-studio-runtimes/vcredist-VS2015/vc_redist.x64.exe>)
  * [x86](<https://mapbox.s3.amazonaws.com/windows-builds/visual-studio-runtimes/vcredist-VS2015/vc_redist.x86.exe>)

## Build Setup

There is no need to manually download any dependencies, they all get downloaded automatically when needed.


```
git clone https://github.com/mapbox/windows-builds.git
cd windows-builds
settings.bat
```

This defines default options to get a quick 64bit build of mapnik: e.g dependencies are not compiled, but **already compiled binary dependencies** get downloaded.

### Options for settings.bat ([see source for overridable parameters](/settings.bat)):

    settings.bat ["OVERRIDABLE-PARAM=VALUE"] ["OVERRIDABLE-PARAM-TWO=VALUE"]

You can combine as many overridable parameters as you like, **but each one has to be quoted with double quotes!**

Examples:
* Turning on compilation of dependencies: `settings "FASTBUILD=0"`
* Building 32bit and using mapnik branch `win-perf`: `settings "TARGET_ARCH=32" "MAPNIKBRANCH=win-perf"`


## Building mapnik and node-mapnik

    scripts\build.bat

With `"FASTBUILD=1"` (the default):
* downloads pre-compiled dependencies
* pulls latest mapnik (honoring `MAPNIKBRANCH`)
* builds mapnik only
* to also build node-mapnik, issue `scripts\build_node_mapnik.bat` afterwards

With `"FASTBUILD=0"`:
* downloads/pulls source and builds each dependencies
* pulls latest mapnik (honoring `MAPNIKBRANCH`)
* builds mapnik
* pulls and builds nodejs
* pulls latest node-mapnik (honoring `NODEMAPNIKBRANCH`)
* builds node-mapnik

With `"PACKAGEMAPNIK=1"` (the default) a mapnik SDK package is created, including all necessary header files, libs and DLLs.

The package will be created in the directory `packages\mapnik-<MAPNIKBRANCH>\mapnik-gyp` with this name:

    mapnik-win-sdk-<MSBUILD VERSION>-<ARCHITECTURE>-<MAPNIK GIT TAG>.7z

 e.g.

    mapnik-win-sdk-14.0-x64-v3.0.0-rc1-242-g2a33ead.7z


## Building osmium

    scripts\build_libosmium_deps
    scripts\package_libosmium_deps
    scripts\build_libosmium vs
    scripts\build_osmium-tool

## Building node-gdal

    scripts\build_node_gdal.bat

## Building nodejs

    scripts\build_node

## Building osrm - WORK IN PROGRESS

    scripts\build_osrm builddeps

Will create:
* `bin\osrm-deps-win-x64-14.0.7z`
* `bin\osrm-release-<GIT-TAG>-x64-win-14.0.7z`
