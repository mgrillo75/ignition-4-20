[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$RequireTagPathParam,
    [switch]$RequireTagPathInputConfig,
    [switch]$RequireDropConfig
)

$ErrorActionPreference = "Stop"

function Has-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    if ($Object -is [System.Collections.IDictionary]) {
        return $Object.Contains($Name)
    }
    return $Object.PSObject.Properties.Match($Name).Count -gt 0
}

function Get-PropValue {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-Tree {
    param(
        $Node,
        [string]$NodePath,
        [System.Collections.Generic.List[string]]$Issues
    )

    if ($null -eq $Node) {
        $Issues.Add("${NodePath}: null component")
        return
    }
    if (-not (Has-Prop $Node "version") -or $Node.version -ne 0) {
        $Issues.Add("${NodePath}: missing or non-zero version")
    }
    if (-not (Has-Prop $Node "meta") -or -not (Has-Prop $Node.meta "name")) {
        $Issues.Add("${NodePath}: missing meta.name")
    }
    if (-not (Has-Prop $Node "position")) {
        $Issues.Add("${NodePath}: missing position")
    }

    if ((Has-Prop $Node "children") -and $null -ne $Node.children) {
        $children = @($Node.children)
        for ($i = 0; $i -lt $children.Count; $i++) {
            $child = $children[$i]
            $name = "children[$i]"
            if ((Has-Prop $child "meta") -and (Has-Prop $child.meta "name") -and -not [string]::IsNullOrWhiteSpace([string]$child.meta.name)) {
                $name = [string]$child.meta.name
            }
            Test-Tree -Node $child -NodePath "$NodePath/$name" -Issues $Issues
        }
    }
}

function Validate-UdtPattern {
    param(
        $View,
        [string]$Target,
        [System.Collections.Generic.List[string]]$Issues
    )

    if ($RequireTagPathParam) {
        if (-not (Has-Prop $View "params") -or -not (Has-Prop $View.params "tagPath")) {
            $Issues.Add("${Target}: missing params.tagPath")
        }
    }

    if ($RequireTagPathInputConfig) {
        if (-not (Has-Prop $View "propConfig")) {
            $Issues.Add("${Target}: missing propConfig for params.tagPath input config")
        } else {
            $tagPathConfig = Get-PropValue -Object $View.propConfig -Name "params.tagPath"
            if ($null -eq $tagPathConfig) {
                $Issues.Add("${Target}: missing propConfig['params.tagPath']")
            } elseif (-not (Has-Prop $tagPathConfig "paramDirection") -or ([string]$tagPathConfig.paramDirection -ne "input")) {
                $Issues.Add("${Target}: propConfig['params.tagPath'].paramDirection must be 'input'")
            }
        }
    }

    if ($RequireDropConfig) {
        if (-not (Has-Prop $View "props") -or -not (Has-Prop $View.props "dropConfig")) {
            $Issues.Add("${Target}: missing props.dropConfig")
        } elseif (-not (Has-Prop $View.props.dropConfig "udts")) {
            $Issues.Add("${Target}: props.dropConfig missing 'udts'")
        } else {
            $udts = @($View.props.dropConfig.udts)
            if ($udts.Count -eq 0) {
                $Issues.Add("${Target}: props.dropConfig.udts must contain at least one row")
            } else {
                for ($i = 0; $i -lt $udts.Count; $i++) {
                    $row = $udts[$i]
                    if (-not (Has-Prop $row "action")) {
                        $Issues.Add("${Target}: props.dropConfig.udts[$i] missing 'action'")
                    }
                    if (-not (Has-Prop $row "param")) {
                        $Issues.Add("${Target}: props.dropConfig.udts[$i] missing 'param'")
                    }
                    if (-not (Has-Prop $row "type")) {
                        $Issues.Add("${Target}: props.dropConfig.udts[$i] missing 'type'")
                    }
                }
            }
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

$issues = New-Object System.Collections.Generic.List[string]
foreach ($target in $targets) {
    try {
        $view = Get-Content -Path $target -Raw | ConvertFrom-Json
    } catch {
        $issues.Add("${target}: invalid JSON")
        continue
    }

    if (-not (Has-Prop $view "root")) {
        $issues.Add("${target}: missing root")
        continue
    }
    Test-Tree -Node $view.root -NodePath $target -Issues $issues
    Validate-UdtPattern -View $view -Target $target -Issues $issues
}

if ($issues.Count -gt 0) {
    Write-Output "Validation failed with $($issues.Count) issue(s):"
    foreach ($issue in $issues) {
        Write-Output "- $issue"
    }
    exit 1
}

Write-Output "Validation passed for $($targets.Count) view file(s)."
exit 0
