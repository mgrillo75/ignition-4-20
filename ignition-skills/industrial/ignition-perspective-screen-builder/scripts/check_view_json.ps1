[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [switch]$Strict
)

function Has-Prop {
    param(
        $Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    return $Object.PSObject.Properties.Match($Name).Count -gt 0
}

function Test-ComponentTree {
    param(
        $Component,
        [string]$ComponentPath,
        [System.Collections.Generic.List[string]]$Issues
    )

    if ($null -eq $Component) {
        $Issues.Add("${ComponentPath}: component is null.")
        return
    }

    if ($Strict) {
        if (-not (Has-Prop $Component "version")) {
            $Issues.Add("${ComponentPath}: missing 'version'.")
        } elseif ($Component.version -ne 0) {
            $Issues.Add("${ComponentPath}: expected version 0, found '$($Component.version)'.")
        }
    }

    if (-not (Has-Prop $Component "meta") -or $null -eq $Component.meta) {
        $Issues.Add("${ComponentPath}: missing 'meta' object.")
    } elseif (-not (Has-Prop $Component.meta "name") -or [string]::IsNullOrWhiteSpace([string]$Component.meta.name)) {
        $Issues.Add("${ComponentPath}: missing 'meta.name'.")
    }

    if ($Strict -and -not (Has-Prop $Component "position")) {
        $Issues.Add("${ComponentPath}: missing 'position' object.")
    }

    if ((Has-Prop $Component "children") -and $null -ne $Component.children) {
        $children = @($Component.children)
        for ($i = 0; $i -lt $children.Count; $i++) {
            $child = $children[$i]
            $childName = "children[$i]"

            if ((Has-Prop $child "meta") -and $null -ne $child.meta -and (Has-Prop $child.meta "name")) {
                if (-not [string]::IsNullOrWhiteSpace([string]$child.meta.name)) {
                    $childName = [string]$child.meta.name
                }
            }

            Test-ComponentTree -Component $child -ComponentPath "$ComponentPath/$childName" -Issues $Issues
        }
    }
}

$targets = @()
if (Test-Path $Path -PathType Leaf) {
    $targets = @((Resolve-Path $Path).Path)
} elseif (Test-Path $Path -PathType Container) {
    $targets = Get-ChildItem -Path $Path -Recurse -Filter "view.json" | Select-Object -ExpandProperty FullName
} else {
    throw "Path not found: $Path"
}

if ($targets.Count -eq 0) {
    throw "No view.json files found at path: $Path"
}

$totalIssues = New-Object System.Collections.Generic.List[string]

foreach ($target in $targets) {
    try {
        $raw = Get-Content -Path $target -Raw
        $view = $raw | ConvertFrom-Json
    } catch {
        $totalIssues.Add("${target}: invalid JSON ($($_.Exception.Message)).")
        continue
    }

    if (-not (Has-Prop $view "root") -or $null -eq $view.root) {
        $totalIssues.Add("${target}: missing root component.")
        continue
    }

    $issues = New-Object System.Collections.Generic.List[string]
    Test-ComponentTree -Component $view.root -ComponentPath $target -Issues $issues

    foreach ($issue in $issues) {
        $totalIssues.Add($issue)
    }
}

if ($totalIssues.Count -gt 0) {
    Write-Output "Validation failed with $($totalIssues.Count) issue(s):"
    foreach ($issue in $totalIssues) {
        Write-Output "- $issue"
    }
    exit 1
}

Write-Output "Validation passed for $($targets.Count) file(s)."
exit 0