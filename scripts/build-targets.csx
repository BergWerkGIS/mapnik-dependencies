KeyValuePair<string, string> zlib = new KeyValuePair<string, string>( "zlib", @"scripts\build_zlib.bat" );
KeyValuePair<string, string> libpng = new KeyValuePair<string, string>( "libpng", @"scripts\build_libpng.bat" );
KeyValuePair<string, string> jpeg = new KeyValuePair<string, string>( "jpeg", @"scripts\build_libjpegturbo" );
KeyValuePair<string, string> tiff = new KeyValuePair<string, string>( "tiff", @"scripts\build_tiff.bat" );
KeyValuePair<string, string> icu = new KeyValuePair<string, string>( "icu", @"scripts\build_icu.bat" );
KeyValuePair<string, string> python = new KeyValuePair<string, string>( "python", @"scripts\build_python.bat" );
KeyValuePair<string, string> boost = new KeyValuePair<string, string>( "boost", @"scripts\build_boost.bat" );
KeyValuePair<string, string> webp = new KeyValuePair<string, string>( "webp", @"scripts\build_webp.bat" );
KeyValuePair<string, string> freetype = new KeyValuePair<string, string>( "freetype", @"scripts\build_freetype.bat" );
KeyValuePair<string, string> proj4 = new KeyValuePair<string, string>( "proj4", @"scripts\build_proj4.bat" );
KeyValuePair<string, string> protobuf = new KeyValuePair<string, string>( "protobuf", @"scripts\build_protobuf-%PROTOBUF_VERSION%.bat" );
KeyValuePair<string, string> sparsehash = new KeyValuePair<string, string>( "sparsehash", @"scripts\build_sparsehash.bat" );
KeyValuePair<string, string> osmpbf = new KeyValuePair<string, string>( "osmpbf", @"scripts\build_osmpbf.bat" );
KeyValuePair<string, string> bzip2 = new KeyValuePair<string, string>( "bzip2", @"scripts\build_bzip2.bat" );
KeyValuePair<string, string> pixman = new KeyValuePair<string, string>( "pixman", @"scripts\build_pixman.bat" );
KeyValuePair<string, string> cairo = new KeyValuePair<string, string>( "cairo", @"scripts\build_cairo.bat" );
KeyValuePair<string, string> sqlite = new KeyValuePair<string, string>( "sqlite", @"scripts\build_sqlite.bat" );
KeyValuePair<string, string> expat = new KeyValuePair<string, string>( "expat", @"scripts\build_expat.bat" );
KeyValuePair<string, string> gdal = new KeyValuePair<string, string>( "gdal", @"scripts\build_gdal.bat" );
KeyValuePair<string, string> libpq = new KeyValuePair<string, string>( "libpq", @"scripts\build_libpq.bat" );
KeyValuePair<string, string> harfbuzz = new KeyValuePair<string, string>( "harfbuzz", @"scripts\build_harfbuzz.bat" );
KeyValuePair<string, string> mapnik = new KeyValuePair<string, string>( "mapnik", @"scripts\build_mapnik.bat" );

List<KeyValuePair<string, string>> target_mapnik = new List<KeyValuePair<string, string>>() {
	zlib,
	libpng,
	jpeg,
	tiff,
	icu,
	python,
	boost,
	webp,
	freetype,
	proj4,
	protobuf,
	sparsehash,
//	osmpbf,
	bzip2,
	pixman,
	cairo,
	sqlite,
	expat,
	gdal,
	libpq,
	harfbuzz,
	mapnik
};

//TODO! define other targets:
//libosmium
//osrm
//....
