param(
    [string]$ModuleRoot = "C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules\isometric-perspective-components",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ModuleRoot)) {
    throw "Module root not found: $ModuleRoot"
}

$resolvedModuleRoot = (Resolve-Path -LiteralPath $ModuleRoot).Path
$gradlewPath = Join-Path $resolvedModuleRoot "gradlew.bat"

if (-not (Test-Path -LiteralPath $gradlewPath)) {
    throw "gradlew.bat not found at: $gradlewPath"
}

Push-Location $resolvedModuleRoot
try {
    if ($Clean) {
        & $gradlewPath clean --console=plain --no-daemon
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle clean failed with exit code $LASTEXITCODE"
        }
    }

    & $gradlewPath build --console=plain --no-daemon
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle build failed with exit code $LASTEXITCODE"
    }

    $buildDir = Join-Path $resolvedModuleRoot "build"
    $modlArtifacts = Get-ChildItem -LiteralPath $buildDir -Filter "*.modl" -File | Sort-Object LastWriteTime -Descending

    if (-not $modlArtifacts -or $modlArtifacts.Count -eq 0) {
        throw "No .modl artifact found under: $buildDir"
    }

    $latestModl = $modlArtifacts[0]

    Write-Host ("MODL_PATH={0}" -f $latestModl.FullName)
    Write-Host ("MODL_LAST_WRITE_UTC={0}" -f $latestModl.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ"))
    Write-Host ("MODL_SIZE_BYTES={0}" -f $latestModl.Length)
}
finally {
    Pop-Location
}

