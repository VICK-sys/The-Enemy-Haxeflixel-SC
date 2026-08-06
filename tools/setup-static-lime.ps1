[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path ([System.IO.Path]::GetTempPath()) "lime-8.3.2-static")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($env:PROCESSOR_ARCHITECTURE))
{
    $env:PROCESSOR_ARCHITECTURE = if ([Environment]::Is64BitOperatingSystem) { "AMD64" } else { "x86" }
}

$tag = "8.3.2"
$commit = "d78d5be8a29de6ad649ffe4684ee435f76fe051b"
$repository = "https://github.com/openfl/lime.git"

$limePaths = @(& haxelib path lime)
if ($LASTEXITCODE -ne 0)
{
    throw "Could not locate Lime through Haxelib."
}

$limeSourceDirectory = $limePaths | Where-Object { $_ -match '[/\\]src[/\\]?$' } | Select-Object -First 1
if ([string]::IsNullOrWhiteSpace($limeSourceDirectory))
{
    throw "Haxelib returned no Lime source directory."
}

$limeSourceDirectory = $limeSourceDirectory.TrimEnd([char[]]@('/', '\'))
$limeRoot = Split-Path -Parent $limeSourceDirectory
$manifest = Get-Content -Raw -LiteralPath (Join-Path $limeRoot "haxelib.json") | ConvertFrom-Json
if ($manifest.version -ne $tag)
{
    throw "Static build requires Lime $tag. Current version is $($manifest.version)."
}

$destination = Join-Path $limeRoot "ndll\Windows64\liblime-19.lib"
if (Test-Path -LiteralPath $destination)
{
    Write-Host "Static Lime archive already exists: $destination" -ForegroundColor Green
    exit 0
}

if (-not (Test-Path -LiteralPath $SourcePath))
{
    & git clone --depth 1 --branch $tag --recurse-submodules --shallow-submodules $repository $SourcePath
    if ($LASTEXITCODE -ne 0)
    {
        throw "Lime source clone failed with exit code $LASTEXITCODE."
    }
}

$sourceCommit = (& git -C $SourcePath rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sourceCommit -ne $commit)
{
    throw "Lime source path is not the expected $tag checkout: $SourcePath"
}

& git -C $SourcePath submodule update --init --recursive --depth 1
if ($LASTEXITCODE -ne 0)
{
    throw "Lime submodule update failed with exit code $LASTEXITCODE."
}

$project = Join-Path $SourcePath "project"
& haxelib run lime rebuild $project windows -64 -static -clean
if ($LASTEXITCODE -ne 0)
{
    throw "Static Lime rebuild failed with exit code $LASTEXITCODE."
}

$archive = Join-Path $SourcePath "ndll\Windows64\liblime-19.lib"
if (-not (Test-Path -LiteralPath $archive))
{
    throw "Static Lime rebuild produced no archive: $archive"
}

Copy-Item -LiteralPath $archive -Destination $destination
if ((Get-FileHash -LiteralPath $archive).Hash -ne (Get-FileHash -LiteralPath $destination).Hash)
{
    throw "Static Lime archive failed copy validation."
}

Write-Host "Static Lime archive installed: $destination" -ForegroundColor Green
