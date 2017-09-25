$ErrorActionPreference = 'Stop'
$nl = [System.Environment]::NewLine
$cnt_fail = 0
$cnt_success = 0

$needed_env_vars = @(
    'ROOTDIR'
    , 'PKGDIR'
    , 'BOOST_VERSION'
    , 'TOOLS_VERSION'
)

$tools_version = "vc" + $env:TOOLS_VERSION.Replace('.','')
$osrm_deps_dir = "$env:PKGDIR\osrm-deps\osrm-deps\"
$osrm_libs_dest_dir = "${osrm_deps_dir}libs\"
$osrm_libs_bin_dest_dir = "${osrm_libs_dest_dir}bin\"
$osrm_libs_include_dest_dir = "${osrm_libs_dest_dir}include\"
$osrm_libs_lib_dest_dir = "${osrm_libs_dest_dir}lib\"
$osrm_tbb_lib_dest_dir = "${osrm_deps_dir}tbb\lib\intel64\vc14\"
$osrm_tbb_include_dest_dir = "${osrm_deps_dir}tbb\"


#boost
$boost_lib_src_dir = "$env:PKGDIR\boost\stage\lib\"
$boost_lib_dest_dir = "${osrm_deps_dir}boost\lib\"
$boost_include_src_dir = "$env:PKGDIR\boost\boost\"
$boost_include_dest_dir = "${osrm_deps_dir}boost\include\boost-1_$env:BOOST_VERSION\"

#tbb
$tbb_lib_src_dir = "$env:PKGDIR\tbb\lib\v140\x64\Release\"
$tbb_include_src_dir = "$env:PKGDIR\tbb\include\"

#delete existing deps dir
&ddt /Q $osrm_deps_dir

# hashtable with destinations and corresponding files in arrays
$file_list = @{
    "$boost_lib_dest_dir" = @(
        ("$boost_lib_src_dir" + "libboost_chrono-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_date_time-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_filesystem-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_iostreams-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_program_options-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_regex-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_system-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_thread-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_unit_test_framework-$tools_version-mt-1_$env:BOOST_VERSION.lib"),
        ("$boost_lib_src_dir" + "libboost_zlib-$tools_version-mt-1_$env:BOOST_VERSION.lib")
    );
    "$boost_include_dest_dir" = @(
        ("$boost_include_src_dir" + "*.*")
    );
    "$osrm_libs_bin_dest_dir" = @(
        ("${env:PKGDIR}\lua\build\RelWithDebInfo\lua.dll"),
        ("${env:PKGDIR}\expat\win32\bin\Release\libexpat.dll"),
        ("${tbb_lib_src_dir}tbb.dll"),
        ("${tbb_lib_src_dir}tbbmalloc.dll"),
        ("${tbb_lib_src_dir}tbbmalloc_proxy.dll")
    );
    "$osrm_libs_include_dest_dir" = @(
        ("$env:PKGDIR" + "\bzip2\bzlib.h"),
        ("$env:PKGDIR" + "\expat\lib\expat.h"),
        ("$env:PKGDIR" + "\expat\lib\expat_external.h"),
        ("$env:PKGDIR" + "\lua\src\lauxlib.h"),
        ("$env:PKGDIR" + "\lua\src\lua.h"),
        ("$env:PKGDIR" + "\lua\src\lua.hpp"),
        ("$env:PKGDIR" + "\lua\src\luaconf.h"),
        ("$env:PKGDIR" + "\lua\src\lualib.h"),
        ("$env:PKGDIR" + "\stxxl\include\stxxl.h"),
        ("$env:PKGDIR" + "\zlib\zconf.h"),
        ("$env:PKGDIR" + "\zlib\zlib.h"),
        ("$env:PKGDIR" + "\luabind\luabind\*.*"),
        ("$env:PKGDIR" + "\stxxl\include\stxxl\*.*")
    );
    "$osrm_libs_lib_dest_dir" = @(
        ("$env:PKGDIR" + "\bzip2\libbz2.lib"),
        ("$env:PKGDIR" + "\expat\win32\bin\Release\libexpat.lib"),
        ("$env:PKGDIR" + "\lua\build\RelWithDebInfo\lua.lib"),
        ("$env:PKGDIR" + "\luabind\build\src\RelWithDebInfo\luabind.lib"),
        ("$env:PKGDIR" + "\stxxl\build\lib\RelWithDebInfo\stxxl.lib"),
        ("$env:PKGDIR" + "\zlib\zlib.lib")
    );
    "$osrm_tbb_lib_dest_dir" = @(
        ("$tbb_lib_src_dir" + "tbb.lib"),
        ("$tbb_lib_src_dir" + "tbbmalloc.lib"),
        ("$tbb_lib_src_dir" + "tbbmalloc_proxy.lib")
    );
    "$osrm_tbb_include_dest_dir" = @(
        ("$tbb_include_src_dir" + "*.*")
    );
};


function Write-Callstack([System.Management.Automation.ErrorRecord]$ErrorRecord=$null, [int]$Skip=1){
    Write-Host # blank line
    if ($ErrorRecord){
        Write-Host -ForegroundColor Red "$ErrorRecord $($ErrorRecord.InvocationInfo.PositionMessage)"

        if ($ErrorRecord.Exception){
            Write-Host -ForegroundColor Red $ErrorRecord.Exception
        }

        if ((Get-Member -InputObject $ErrorRecord -Name ScriptStackTrace) -ne $null) {
            #PS 3.0 has a stack trace on the ErrorRecord; if we have it, use it & skip the manual stack trace below
            Write-Host -ForegroundColor Red $ErrorRecord.ScriptStackTrace
            return
        }
    }

    Get-PSCallStack | Select -Skip $Skip | % {
        Write-Host -ForegroundColor Yellow -NoNewLine "! "
        Write-Host -ForegroundColor Red $_.Command $_.Location $(if ($_.Arguments.Length -le 80) { $_.Arguments })
    }
}


Function test-env-var() {
    $env_err = @()
    foreach($ev in $needed_env_vars){
        if (-not(Test-Path "Env:\$ev")){
            $env_err += , $ev
        }
    }
    return $env_err
}


Function copy-all-files(){

    $err_files = @()

    $file_list.GetEnumerator() | % {

        $dest = $_.Key
        if($env:VERBOSE -eq 1){ Write-Host $nl$nl "dest ---->" $dest $nl -ForegroundColor Blue; }

        foreach($file in $_.Value){
            try {
                if($env:VERBOSE -eq 1){ Write-Host "copying $file" -ForegroundColor Yellow; }
                if(!(Test-Path -Path $dest )){
                    #!!! capture output of New-Item, otherwise it will write
                    #to the outputpipeline of this function!!!
                    $bla = New-Item -ItemType Directory $dest;
                }

                $file_name = Split-Path -Leaf "$file"
                if($file_name -eq "*.*"){
                   $src_dir = Split-Path "$file"
                   Copy-Item -Path $src_dir -Destination $dest -Recurse -Force
                   $script:cnt_success += (Get-ChildItem $src_dir -Recurse).Count - 1
                } ElseIf($file_name -eq "libbz2.lib"){
                    #rename to bzip2.lib, otherwise cmake won't find it
                    Copy-Item $file "${dest}bzip2.lib" -Force
               } else {
                    Copy-Item $file $dest -Force
               }
               $script:cnt_success++
            }
            catch {
                $script:cnt_fail++
                $err_files += ,$file
                Write-Host "COPY FAIL $file" -ForegroundColor Yellow
                Write-Host $_.Exception.Message $nl -ForegroundColor Yellow
                Write-Host $_.Exception|format-list -Force
                Write-Host "$Error"
                Write-Host "$Error[0]"
                Write-Callstack $Error[0]
            }
        }
    }
    return $err_files
}


Function main(){

    $err_line = "$nl=!=!=!=!=!=!=!=!=!=!= ERROR COPY OSRM DEPS =!=!=!=!=!=!=!=!=!=!=$nl"


    try {

        Write-Host "$nl============= COPY OSRM DEPS ====================" -ForegroundColor Green

        $env_err = test-env-var
        if($env_err.count -gt 0){
            Write-Host $err_line -ForegroundColor Red
            Write-Host "Env vars not set:$nl", ($env_err -join ", ") -ForegroundColor Red
            exit 1
        }

        $files_err = @()
        $files_err = copy-all-files
        if($files_err.Count -gt 0){
            Write-Host $err_line -ForegroundColor Red
            Write-Host "File copy failed (details above):$nl", ($files_err -join $nl) -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "EXCEPTION"
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.Exception|format-list -force
        Write-Host "$Error"
        Write-Host "$Error[0]"
        Write-Callstack $Error[0]
        exit 1
    }
    finally {
        Write-Host "$script:cnt_success files copied, $script:cnt_fail failed"
        Write-Host "============= DONE COPY OSRM DEPS ================$nl" -ForegroundColor Green
    }
}

main


