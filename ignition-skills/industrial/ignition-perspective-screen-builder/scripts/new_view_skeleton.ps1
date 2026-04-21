[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ViewPath,

    [ValidateSet("flex", "coord", "column", "breakpoint")]
    [string]$Container = "flex",

    [int]$Width = 1280,
    [int]$Height = 720,

    [string]$ProjectRoot,

    [switch]$Force,
    [switch]$DryRun
)

function Resolve-ProjectRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $current = Resolve-Path $StartPath
    while ($null -ne $current) {
        $candidate = Join-Path $current.Path "com.inductiveautomation.perspective"
        if (Test-Path $candidate -PathType Container) {
            return $current.Path
        }

        $parent = Split-Path -Path $current.Path -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) {
            break
        }
        $current = Resolve-Path $parent
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Resolve-ProjectRoot -StartPath (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    throw "ProjectRoot was not found. Run this from your project folder or pass -ProjectRoot explicitly."
}

$trimmedPath = $ViewPath.Trim().Trim('/','\\')
if ([string]::IsNullOrWhiteSpace($trimmedPath)) {
    throw "ViewPath cannot be empty."
}

$viewsRoot = Join-Path $ProjectRoot "com.inductiveautomation.perspective\\views"
$segments = $trimmedPath -split "[/\\\\]+" | Where-Object { $_ -and $_.Trim().Length -gt 0 }
$viewDir = $viewsRoot
foreach ($segment in $segments) {
    $viewDir = Join-Path $viewDir $segment
}
$viewFile = Join-Path $viewDir "view.json"

if ((Test-Path $viewFile) -and -not $Force) {
    throw "View already exists at '$viewFile'. Use -Force to overwrite."
}

$rootType = switch ($Container) {
    "flex" { "ia.container.flex" }
    "coord" { "ia.container.coord" }
    "column" { "ia.container.column" }
    "breakpoint" { "ia.container.breakpoint" }
}

$rootProps = switch ($Container) {
    "flex" {
        [ordered]@{
            direction = "column"
            justify = "flex-start"
            alignItems = "stretch"
            wrap = "nowrap"
            style = [ordered]@{}
        }
    }
    "coord" {
        [ordered]@{
            mode = "fixed"
            style = [ordered]@{}
        }
    }
    "column" {
        [ordered]@{
            style = [ordered]@{}
        }
    }
    "breakpoint" {
        [ordered]@{
            breakpoints = @(
                [ordered]@{ name = "small"; width = 0 },
                [ordered]@{ name = "medium"; width = 768 },
                [ordered]@{ name = "large"; width = 1200 }
            )
            style = [ordered]@{}
        }
    }
}

$viewObject = [ordered]@{
    custom = [ordered]@{}
    params = [ordered]@{}
    props = [ordered]@{
        defaultSize = [ordered]@{
            width = $Width
            height = $Height
        }
    }
    root = [ordered]@{
        type = $rootType
        version = 0
        props = $rootProps
        meta = [ordered]@{
            name = "root"
        }
        position = [ordered]@{}
        custom = [ordered]@{}
        children = @()
        events = [ordered]@{}
        scripts = [ordered]@{}
    }
}

$json = $viewObject | ConvertTo-Json -Depth 40

if ($DryRun) {
    Write-Output "Dry run only. Target file: $viewFile"
    Write-Output $json
    exit 0
}

New-Item -ItemType Directory -Path $viewDir -Force | Out-Null
Set-Content -Path $viewFile -Value $json -Encoding utf8
Write-Output "Created view skeleton: $viewFile"