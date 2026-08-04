<#
.SYNOPSIS
Builds THE ENEMY and, on request, runs the instrumented probe build.

.DESCRIPTION
Without -Probe the script builds both targets and stops.

With -Probe the script runs the full instrumented loop: it builds Windows with
-Dprobe, runs the game, requires a freshly written probe_out.txt, prints it,
removes every "#if probe" block from the source, and rebuilds both targets
clean. Instrumentation is removed even when a step fails.

A successful build is not gameplay verification. A probe run measures one
change. Every gameplay change needs a probe that shows the new behaviour and a
control case that must stay unchanged.

.PARAMETER Probe
Run the instrumented loop instead of a plain build.

.PARAMETER KeepProbe
Leave the instrumentation in place after the run. Use this only while writing a
probe. The script fails if the working tree still holds probe blocks at the end.

.PARAMETER Timeout
Seconds to wait for the probe build to finish before giving up. Default 300.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools/verify.ps1

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools/verify.ps1 -Probe
#>
[CmdletBinding()]
param(
    [switch]$Probe,
    [switch]$KeepProbe,
    [int]$Timeout = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root "export\windows\bin\Enemy.exe"
$probeOut = Join-Path $root "probe_out.txt"

function Write-Step([string]$text)
{
    Write-Host ""
    Write-Host "== $text" -ForegroundColor Cyan
}

function Stop-Game
{
    # A running Enemy.exe holds lime.ndll and the Windows link step fails.
    # No process is the normal case and is not an error.
    $running = Get-Process -Name "Enemy" -ErrorAction SilentlyContinue
    if ($null -eq $running)
    {
        return
    }
    $running | Stop-Process -Force
    Start-Sleep -Milliseconds 400
}

function Invoke-Build([string]$target, [switch]$WithProbe)
{
    if ($target -eq "windows")
    {
        Stop-Game
    }

    $label = if ($WithProbe) { "$target -Dprobe" } else { $target }
    Write-Step "Building $label"

    if ($WithProbe)
    {
        & haxelib run lime build $target -Dprobe
    }
    else
    {
        & haxelib run lime build $target
    }

    if ($LASTEXITCODE -ne 0)
    {
        throw "Build of $label failed with exit code $LASTEXITCODE."
    }
}

function Get-InstrumentedFiles
{
    $source = Join-Path $root "source"
    if (-not (Test-Path $source))
    {
        return @()
    }
    return @(
        Get-ChildItem -Path $source -Filter *.hx -Recurse -File |
            Where-Object { (Get-Content -Raw -LiteralPath $_.FullName) -match '(?m)^\s*#if probe\s*$' } |
            Select-Object -ExpandProperty FullName
    )
}

function Remove-ProbeBlocks([string]$path)
{
    $lines = [System.IO.File]::ReadAllText($path) -split "`r?`n"
    $out = New-Object System.Collections.Generic.List[string]
    $removed = 0
    $i = 0

    while ($i -lt $lines.Count)
    {
        if ($lines[$i].Trim() -ne "#if probe")
        {
            $out.Add($lines[$i])
            $i++
            continue
        }

        # Keep the #else arm, drop the probe arm, and track nested conditionals
        # so an inner #end does not close the outer block early.
        $depth = 1
        $inElse = $false
        $keep = New-Object System.Collections.Generic.List[string]
        $i++

        while ($i -lt $lines.Count -and $depth -gt 0)
        {
            $trimmed = $lines[$i].Trim()
            if ($trimmed -like "#if*")
            {
                $depth++
            }
            elseif ($trimmed -eq "#end")
            {
                $depth--
                if ($depth -eq 0)
                {
                    $i++
                    break
                }
            }
            elseif ($trimmed -eq "#else" -and $depth -eq 1)
            {
                $inElse = $true
                $i++
                continue
            }

            if ($inElse)
            {
                $keep.Add($lines[$i])
            }
            $i++
        }

        if ($depth -gt 0)
        {
            throw "Unterminated '#if probe' block in $path. Strip it by hand."
        }

        $out.AddRange($keep)
        $removed++
    }

    $text = [string]::Join("`n", $out)
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, "`n{3,}", "`n`n")

    # No BOM. Windows PowerShell 5.1 adds one through Set-Content and Out-File.
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $text, $utf8)

    return $removed
}

function Clear-Instrumentation
{
    # An empty array returned from a function unrolls to $null, so wrap it.
    $files = @(Get-InstrumentedFiles)
    if ($files.Count -eq 0)
    {
        return $false
    }

    Write-Step "Removing instrumentation from $($files.Count) file(s)"
    foreach ($file in $files)
    {
        $n = Remove-ProbeBlocks $file
        $short = $file.Substring($root.Length + 1)
        Write-Host "  $short - $n block(s) removed"
    }
    return $true
}

function Invoke-Probe
{
    $before = @(Get-InstrumentedFiles)
    if ($before.Count -eq 0)
    {
        throw "No '#if probe' blocks found under source. Instrument the change first."
    }

    Write-Host "Instrumented files:"
    foreach ($file in $before)
    {
        Write-Host "  $($file.Substring($root.Length + 1))"
    }

    # An old result file would otherwise pass for this run's output.
    if (Test-Path $probeOut)
    {
        Remove-Item -LiteralPath $probeOut -Force
    }
    $startedAt = Get-Date

    Invoke-Build "windows" -WithProbe

    if (-not (Test-Path $exe))
    {
        throw "Probe build reported success but $exe is missing."
    }

    Write-Step "Running the probe"
    Stop-Game
    # Start-Process is a separate invocation and does not set $LASTEXITCODE.
    # Read ExitCode off the returned process object instead.
    $run = Start-Process -FilePath $exe -WorkingDirectory $root -Wait -PassThru
    if ($run.ExitCode -ne 0)
    {
        throw "The probe run exited with code $($run.ExitCode)."
    }

    if (-not (Test-Path $probeOut))
    {
        throw "The probe run wrote no probe_out.txt. Check that it calls lime.system.System.exit(0)."
    }

    $written = (Get-Item -LiteralPath $probeOut).LastWriteTime
    if ($written -lt $startedAt)
    {
        throw "probe_out.txt is stale. It was last written at $written, before this run began at $startedAt."
    }

    $results = Get-Content -Raw -LiteralPath $probeOut
    Write-Step "Probe results"
    Write-Host $results

    if ([string]::IsNullOrWhiteSpace($results))
    {
        throw "probe_out.txt is empty."
    }

    # A probe that reports a tally must report zero failures. A probe that
    # only prints measurements is read by a person, so only FAIL lines block.
    $failures = @([regex]::Matches($results, '(?m)^\s*FAIL\b')).Count
    $tally = [regex]::Match($results, 'FAIL=(\d+)')
    if ($tally.Success)
    {
        $failures = [int]$tally.Groups[1].Value
    }

    if ($failures -gt 0)
    {
        throw "The probe reported $failures failure(s). See the output above."
    }

    Write-Host "Probe passed." -ForegroundColor Green
}

$probeRan = $false
$stripped = $false

try
{
    if ($Probe)
    {
        Invoke-Probe
        $probeRan = $true
    }
}
finally
{
    if ($Probe -and -not $KeepProbe)
    {
        try
        {
            $stripped = Clear-Instrumentation
        }
        catch
        {
            # Never let a cleanup fault replace the fault that caused it.
            Write-Host "Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($probeRan)
            {
                throw
            }
        }
    }
}

if ($Probe -and $KeepProbe)
{
    Write-Host ""
    Write-Host "Instrumentation kept. Rerun without -KeepProbe before you build for release." -ForegroundColor Yellow
    exit 0
}

Invoke-Build "windows"
Invoke-Build "html5"

if (-not $KeepProbe)
{
    $left = @(Get-InstrumentedFiles)
    if ($left.Count -gt 0)
    {
        throw "Instrumentation is still present in $($left.Count) file(s). The tree is not clean."
    }
}

Write-Host ""
if ($probeRan)
{
    $note = if ($stripped) { "instrumentation removed" } else { "no instrumentation to remove" }
    Write-Host "Probe passed, $note, both targets build." -ForegroundColor Green
}
else
{
    Write-Host "Both targets build. No probe was run, so no gameplay behaviour was verified." -ForegroundColor Green
}
