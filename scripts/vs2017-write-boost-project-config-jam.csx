using "System";
using "System.Diagnostics";
using "System.IO";

string clPath;
try {
	using (Process p = new Process()) {
		p.StartInfo = new ProcessStartInfo("cl.exe") {
			UseShellExecute = false,
			CreateNoWindow = true,
		};
		p.Start();
		clPath = p.MainModule.FileName;
	}
} catch (Exception ex) {
	Console.Error.WriteLine($"ERROR executing 'cl.exe':{Environment.NewLine}{ex}");
	Environment.Exit(1);
}

if (string.IsNullOrWhiteSpace(clPath)) {
	Console.Error.WriteLine("could not determine path of 'cl.exe");
	Environment.Exit(1);
}
Console.WriteLine($"cl.exe found: [{clPath}]");

string pkgDir = Environment.GetEnvironmentVariable("PKGDIR");
if (string.IsNullOrWhiteSpace(pkgDir)) {
	Console.Error.WriteLine("environment variable %PKGDIR% not set");
	Environment.Exit(1);
}

string boostDir = Path.Combine(pkgDir, "boost");
if (!Directory.Exists(boostDir)) {
	Console.Error.WriteLine("boost directory not found");
	Environment.Exit(1);
}

string projectConfigJam = Path.Combine(boostDir, "project-config.jam");
Console.WriteLine($"about to write [{projectConfigJam}]");
try {
	// new UTF8Encoding(false) false:without BOM
	using (TextWriter tw = new StreamWriter(projectConfigJam, false, new UTF8Encoding(false))) {
		tw.WriteLine($"import option ; {Environment.NewLine} ");
		tw.WriteLine($"using msvc : 14.1 : {clPath} ; {Environment.NewLine} ");
		tw.WriteLine($"option.set keep-going : false ; {Environment.NewLine} ");
	}
} catch (Exception ex) {
	Console.Error.WriteLine($"ERROR writing '{projectConfigJam}':{Environment.NewLine}{ex}");
	Environment.Exit(1);
}
