param(
    [string]$Workspace = 'E:\1.18\PluginHistory\staging\nampower-build-20261025',
    [switch]$TestsOnly,
    [switch]$IntegrationOnly,
    [string]$PreparedGeneration = '',
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceFull = [IO.Path]::GetFullPath($Workspace)
if (-not $workspaceFull.StartsWith('E:\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Build output must remain on E:' }
$env:TEMP = Join-Path $workspaceFull 'temp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
$portable = Join-Path $workspaceFull 'portable'
$vc = (Get-ChildItem -LiteralPath "$portable\VC\Tools\MSVC" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
if (-not $vc) { throw 'Portable MSVC is not ready' }
$sdk = "$portable\sdk-headers\c\Include\10.0.22621.0"
$sdkLib = "$portable\sdk-x86\c"
$compiler = "$vc\bin\Hostx64\x86\cl.exe"
$librarian = "$vc\bin\Hostx64\x86\lib.exe"
$linker = "$vc\bin\Hostx64\x86\link.exe"
$env:PATH = "$vc\bin\Hostx64\x86;$env:PATH"
$env:INCLUDE = "$vc\include;$sdk\ucrt;$sdk\shared;$sdk\um"
$env:LIB = "$vc\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
foreach ($file in @($compiler, "$sdk\um\Windows.h", "$sdkLib\um\x86\kernel32.Lib", "$sdkLib\ucrt\x86\libucrt.lib")) {
    if (-not (Test-Path -LiteralPath $file)) { throw "Required toolchain file missing: $file" }
}
$buildRoot = Join-Path $workspaceFull ('build-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
if (Test-Path -LiteralPath $buildRoot) { throw 'Fresh build directory already exists' }
New-Item -ItemType Directory -Path $buildRoot -ErrorAction Stop | Out-Null
$flags = @('/nologo','/c','/MT','/O2','/EHsc','/std:c++14','/DNDEBUG','/DWIN32','/D_CRT_SECURE_NO_WARNINGS','/D_SCL_SECURE_NO_WARNINGS','/Gw','/Gy','/Zc:strictStrings','/utf-8')

function Invoke-Response([string]$Executable, [string[]]$Arguments, [string]$Response, [string]$Log) {
    # A response file preserves quoted paths without shell interpolation.
    [IO.File]::WriteAllLines($Response, $Arguments, [Text.UTF8Encoding]::new($false))
    & $Executable "@$Response" *> $Log
    if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $Log -Tail 45 | ForEach-Object { Write-Host $_ }; throw "Build failed; see $Log" }
}
function Build-Objects([string]$Name, [string[]]$Sources, [string[]]$Includes, [string[]]$Extra) {
    $directory = Join-Path $buildRoot $Name
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    if (($Sources | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) } | Group-Object | Where-Object Count -gt 1)) { throw "Duplicate object names in $Name" }
    $arguments = @($flags) + @($Extra) + @('/Fo"' + $directory.Replace('\','/') + '/"')
    $arguments += @($Includes | ForEach-Object { '/I"' + $_ + '"' })
    $arguments += @($Sources | ForEach-Object { '"' + $_ + '"' })
    Invoke-Response $compiler $arguments "$directory\compile.rsp" "$directory\compile.log"
    return @($Sources | ForEach-Object { Join-Path $directory ([IO.Path]::GetFileNameWithoutExtension($_) + '.obj') })
}
function Build-Library([string]$Name, [string[]]$Sources, [string[]]$Includes, [string[]]$Extra) {
    $library = Join-Path $buildRoot "$Name.lib"
    if (Test-Path -LiteralPath $library) { throw "Fresh build unexpectedly contains a library: $library" }
    $objects = Build-Objects $Name $Sources $Includes $Extra
    Invoke-Response $librarian (@('/nologo',('/OUT:"' + $library + '"')) + @($objects | ForEach-Object { '"'+$_+'"' })) "$buildRoot\$Name-lib.rsp" "$buildRoot\$Name-lib.log"
    Write-Output "Built $library"
}

$objects = Build-Objects 'thread-tests' @("$toolRoot\tests\process_threads_test.cpp") @("$toolRoot\include") @('/W4')
$testExe = "$buildRoot\process_threads_test.exe"
Invoke-Response $linker (@('/nologo','/MACHINE:X86',('/OUT:"'+$testExe+'"'),'kernel32.lib') + @($objects | ForEach-Object { '"'+$_+'"' })) "$buildRoot\tests-link.rsp" "$buildRoot\tests-link.log"
Write-Output "Native test executable: $testExe"
foreach ($profile in @('0','1')) {
    $metricObjects = Build-Objects "metrics-$profile" @("$toolRoot\tests\startup_metrics_test.cpp") @("$toolRoot\include") @("/DNAMP_MAINT_PROFILE=$profile")
    $metricArgs = @('/nologo','/MACHINE:X86',('/OUT:"'+$buildRoot+'\startup_metrics_test-'+$profile+'.exe"'),'kernel32.lib')
    $metricArgs += @($metricObjects | ForEach-Object { '"'+$_+'"' })
    Invoke-Response $linker $metricArgs "$buildRoot\metrics-$profile-link.rsp" "$buildRoot\metrics-$profile-link.log"
}
if ($TestsOnly) { exit 0 }

$deps = Join-Path $workspaceFull 'dependency-source'
$boost = "$deps\boost_1_80_0"
$asmjit = "$deps\asmjit-f7de7b8d35c76e2a5f5792971371a9fd39e6557b\src"
$udis = "$deps\udis86-0dc7184bd33b9f2866a2a95acf17b308466a1116"
foreach ($required in @("$boost\boost\version.hpp", "$asmjit\asmjit\asmjit.h", "$udis\scripts\ud_itab.py")) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Dependency source missing: $required" }
}
if (-not (Test-Path -LiteralPath "$udis\libudis86\itab.c")) {
    & $Python "$udis\scripts\ud_itab.py" "$udis\docs\x86\optable.xml" "$udis\libudis86"
    if ($LASTEXITCODE -ne 0) { throw 'udis86 table generation failed' }
}
Build-Library 'asmjit' @((Get-ChildItem "$asmjit\asmjit\base\*.cpp","$asmjit\asmjit\x86\*.cpp").FullName) @($asmjit) @('/DASMJIT_STATIC','/DASMJIT_BUILD_X86','/DASMJIT_BUILD_X64','/GS-','/wd4503','/wd4345','/volatile:iso')
Build-Library 'udis86' @(@('decode.c','itab.c','syn-att.c','syn-intel.c','syn.c','udis86.c') | ForEach-Object { "$udis\libudis86\$_" }) @($udis,"$udis\libudis86") @('/TC','/GS-','/volatile:iso')
Build-Library 'boost-filesystem' @((Get-ChildItem "$boost\libs\filesystem\src\*.cpp").FullName) @($boost) @('/DBOOST_ALL_NO_LIB','/DBOOST_FILESYSTEM_STATIC_LINK','/DBOOST_SYSTEM_STATIC_LINK','/DBOOST_FILESYSTEM_NO_CXX20_ATOMIC_REF')
Build-Library 'boost-program-options' @((Get-ChildItem "$boost\libs\program_options\src\*.cpp").FullName) @($boost) @('/DBOOST_ALL_NO_LIB','/DBOOST_PROGRAM_OPTIONS_STATIC_LINK')

$generationSuffix = if ($PreparedGeneration) { '-' + $PreparedGeneration } else { '' }
& $Python "$toolRoot\record_build_inputs.py" --workspace $workspaceFull --generation $PreparedGeneration --output "$buildRoot\inputs.json"
if ($LASTEXITCODE -ne 0) { throw 'Build input verification failed' }
foreach ($variant in @('original','pss')) {
    $prepared = Get-Content -Raw -LiteralPath "$workspaceFull\prepared-$variant$generationSuffix\prepared.json" | ConvertFrom-Json
    $source = $prepared.source_directory
    $hades = $prepared.hadesmem_directory
    $includes = @("$toolRoot\include","$source\nampower",$source,$boost,"$hades\include\memory","$hades\deps\udis86\udis86","$hades\deps\asmjit\asmjit\src")
    $enabled = if ($variant -eq 'pss') { '1' } else { '0' }
    $extra = @('/DUNICODE','/D_UNICODE','/DASMJIT_STATIC','/DASMJIT_BUILD_X86','/DHADESMEM_NO_PUGIXML','/DBOOST_ALL_NO_LIB',"/DNAMP_MAINT_USE_PSS=$enabled",'/DNAMP_MAINT_PROFILE=1','/Zi',('/Fd"'+$buildRoot+'\'+$variant+'-compiler.pdb"'))
    $artifact = Join-Path $workspaceFull "artifacts\$variant"
    New-Item -ItemType Directory -Path $artifact -Force | Out-Null
    if (-not $IntegrationOnly) {
    $objects = Build-Objects $variant @((Get-ChildItem "$source\nampower\*.cpp").FullName) $includes $extra
    $arguments = @('/nologo','/DLL','/MACHINE:X86',('/OUT:"'+$artifact+'\nampower.dll"'),('/MAP:"'+$artifact+'\nampower.map"'),('/PDB:"'+$artifact+'\nampower.pdb"'),'/DEBUG','/OPT:REF','/OPT:ICF','/DYNAMICBASE','/NXCOMPAT')
    $arguments += @($objects | ForEach-Object { '"'+$_+'"' })
    $arguments += @('asmjit','udis86','boost-filesystem','boost-program-options' | ForEach-Object { '"'+$buildRoot+'\'+$_+'.lib"' })
    $arguments += @('shlwapi.lib','kernel32.lib','user32.lib','crypt32.lib','advapi32.lib','ole32.lib')
    Invoke-Response $linker $arguments "$buildRoot\$variant-link.rsp" "$buildRoot\$variant-link.log"
    Copy-Item -LiteralPath "$buildRoot\inputs.json" -Destination "$artifact\build-inputs.json"
    New-Item -ItemType Directory -Path "$artifact\licenses" -Force | Out-Null
    Get-ChildItem -LiteralPath "$toolRoot\licenses" -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination "$artifact\licenses\$($_.Name)" -Force
    }
    }
    $integrationObjects = Build-Objects "verify-$variant" @("$toolRoot\tests\verify_integration.cpp") $includes $extra
    $testArguments = @('/nologo','/MACHINE:X86',('/OUT:"'+$artifact+'\verify_integration.exe"'),'kernel32.lib')
    $testArguments += @($integrationObjects | ForEach-Object { '"'+$_+'"' })
    Invoke-Response $linker $testArguments "$buildRoot\verify-$variant-link.rsp" "$buildRoot\verify-$variant-link.log"
    Copy-Item -LiteralPath "$source\LICENSE.txt" -Destination "$artifact\LICENSE.nampower.txt"
    Copy-Item -LiteralPath "$buildRoot\inputs.json" -Destination "$artifact\integration-build-inputs.json"
    if (-not $IntegrationOnly) { Get-FileHash -LiteralPath "$artifact\nampower.dll" | Format-List Path,Hash }
}
Write-Output "Build output: $buildRoot"
