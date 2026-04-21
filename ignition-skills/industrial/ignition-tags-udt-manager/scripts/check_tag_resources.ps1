[CmdletBinding()]
param(
    [Alias("ResourcePath")]
    [Parameter(Mandatory = $true)]
    [string]$ProviderPath,
    [string[]]$DefinitionRoots,
    [switch]$AllowUnknownTypeIds,
    [switch]$StrictParameterTokens
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProviderPath)) {
    throw "Path not found: $ProviderPath"
}

function Has-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    if ($Object -is [System.Collections.IDictionary]) {
        return $Object.Contains($Name)
    }
    return $Object.PSObject.Properties.Match($Name).Count -gt 0
}

function Get-ProviderScopedRoot {
    param(
        [string]$Path,
        [string]$Segment
    )

    $normalized = $Path -replace "/", "\"
    $parts = $normalized -split "\\"
    $index = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i].ToLowerInvariant() -eq $Segment.ToLowerInvariant()) {
            $index = $i
            break
        }
    }
    if ($index -lt 0 -or ($index + 1) -ge $parts.Count) {
        return $null
    }
    return ($parts[0..($index + 1)] -join "\")
}

function Get-RelativeDirectoryPrefix {
    param(
        [string]$FilePath,
        [string]$RootPath
    )

    $fileDirectory = (Split-Path -Path $FilePath -Parent).TrimEnd("\")
    $root = $RootPath.TrimEnd("\")
    if ($fileDirectory.Length -le $root.Length) {
        return ""
    }

    $relative = $fileDirectory.Substring($root.Length).TrimStart("\")
    if ([string]::IsNullOrWhiteSpace($relative)) {
        return ""
    }
    return (($relative -split "[\\/]+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "/")
}

function Collect-ParameterBindings {
    param(
        $Object,
        [string]$Path,
        [System.Collections.Generic.List[object]]$Bindings
    )

    if ($null -eq $Object) { return }

    if ($Object -is [System.Array]) {
        for ($i = 0; $i -lt $Object.Count; $i++) {
            Collect-ParameterBindings -Object $Object[$i] -Path "$Path[$i]" -Bindings $Bindings
        }
        return
    }

    if ($Object -is [System.Collections.IDictionary] -or $Object -is [PSCustomObject]) {
        if ((Has-Prop $Object "bindType") -and ([string]$Object.bindType -eq "parameter")) {
            $bindingValue = ""
            if (Has-Prop $Object "binding") {
                $bindingValue = [string]$Object.binding
            }
            $Bindings.Add([pscustomobject]@{
                Path = $Path
                Binding = $bindingValue
            }) | Out-Null
        }

        foreach ($property in $Object.PSObject.Properties) {
            if ($property.Name -eq "tags") {
                continue
            }
            Collect-ParameterBindings -Object $property.Value -Path "$Path/$($property.Name)" -Bindings $Bindings
        }
    }
}

function Get-ParameterTokens {
    param([string]$Binding)
    if ([string]::IsNullOrWhiteSpace($Binding)) {
        return @()
    }
    $matches = [regex]::Matches($Binding, "\{([^{}]+)\}")
    $tokens = @()
    foreach ($match in $matches) {
        $token = $match.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($token)) {
            $tokens += $token
        }
    }
    return $tokens
}

function Validate-ParameterBindings {
    param(
        $Row,
        [string]$FilePath,
        [string]$NodePath,
        [string[]]$AllowedParameters,
        [string[]]$BuiltinParameters,
        [switch]$Strict
    )

    $bindingRefs = New-Object System.Collections.Generic.List[object]
    Collect-ParameterBindings -Object $Row -Path $NodePath -Bindings $bindingRefs
    if ($bindingRefs.Count -eq 0) { return @() }

    $localIssues = New-Object System.Collections.Generic.List[string]
    foreach ($bindingRef in $bindingRefs) {
        $binding = [string]$bindingRef.Binding
        if ([string]::IsNullOrWhiteSpace($binding)) {
            $localIssues.Add("${FilePath}: $($bindingRef.Path) has bindType=parameter with empty binding")
            continue
        }

        if ($Strict) {
            $tokens = Get-ParameterTokens -Binding $binding
            foreach ($token in $tokens) {
                if (($AllowedParameters -contains $token) -or ($BuiltinParameters -contains $token)) {
                    continue
                }
                $localIssues.Add("${FilePath}: $($bindingRef.Path) references unknown parameter token '{$token}'")
            }
        }
    }
    return $localIssues
}

function Validate-TagRows {
    param(
        [System.Array]$Rows,
        [string]$FilePath,
        [string]$NodePath,
        [string[]]$ScopeParameters,
        [switch]$StrictParamTokens,
        [System.Collections.Generic.List[pscustomobject]]$TypeRefs
    )

    $issuesLocal = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Rows) {
        $issuesLocal.Add("${FilePath}: ${NodePath} is null")
        return $issuesLocal
    }

    $builtinParameters = @("TagName")

    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $row = $Rows[$i]
        $entryPath = "$NodePath[$i]"

        if (-not (Has-Prop $row "name") -or [string]::IsNullOrWhiteSpace([string]$row.name)) {
            $issuesLocal.Add("${FilePath}: ${entryPath} missing 'name'")
        }
        if (-not (Has-Prop $row "tagType") -or [string]::IsNullOrWhiteSpace([string]$row.tagType)) {
            $issuesLocal.Add("${FilePath}: ${entryPath} missing 'tagType'")
            continue
        }

        $tagType = [string]$row.tagType
        $activeParameters = @($ScopeParameters)

        if ($tagType -eq "UdtType") {
            if ((Has-Prop $row "parameters") -and $null -ne $row.parameters) {
                if ($row.parameters -is [PSCustomObject] -or $row.parameters -is [System.Collections.IDictionary]) {
                    foreach ($parameter in $row.parameters.PSObject.Properties) {
                        if ([string]::IsNullOrWhiteSpace($parameter.Name)) {
                            $issuesLocal.Add("${FilePath}: ${entryPath} has blank parameter key")
                            continue
                        }
                        $activeParameters += $parameter.Name
                        if ($null -eq $parameter.Value -or -not (Has-Prop $parameter.Value "dataType")) {
                            $issuesLocal.Add("${FilePath}: ${entryPath} parameter '$($parameter.Name)' missing 'dataType'")
                        }
                    }
                } else {
                    $issuesLocal.Add("${FilePath}: ${entryPath} has non-object 'parameters'")
                }
            }
            $activeParameters = @($activeParameters | Select-Object -Unique)
        }

        if ($tagType -eq "UdtInstance") {
            if (-not (Has-Prop $row "typeId") -or [string]::IsNullOrWhiteSpace([string]$row.typeId)) {
                $issuesLocal.Add("${FilePath}: ${entryPath} UdtInstance missing 'typeId'")
            } else {
                $TypeRefs.Add([pscustomobject]@{
                    FilePath = $FilePath
                    NodePath = $entryPath
                    TypeId = [string]$row.typeId
                }) | Out-Null
            }
        }

        $paramIssues = Validate-ParameterBindings -Row $row -FilePath $FilePath -NodePath $entryPath -AllowedParameters $activeParameters -BuiltinParameters $builtinParameters -Strict:$StrictParamTokens
        foreach ($issue in $paramIssues) {
            $issuesLocal.Add($issue)
        }

        if (Has-Prop $row "tags") {
            if ($null -eq $row.tags) {
                $issuesLocal.Add("${FilePath}: ${entryPath} has null 'tags'")
            } elseif (-not ($row.tags -is [System.Array])) {
                $issuesLocal.Add("${FilePath}: ${entryPath} 'tags' must be an array")
            } else {
                $childIssues = Validate-TagRows -Rows @($row.tags) -FilePath $FilePath -NodePath "$entryPath/tags" -ScopeParameters $activeParameters -StrictParamTokens:$StrictParamTokens -TypeRefs $TypeRefs
                foreach ($issue in $childIssues) {
                    $issuesLocal.Add($issue)
                }
            }
        }
    }

    return $issuesLocal
}

function Add-TypeIdsFromDefinitionRoot {
    param(
        [string]$RootPath,
        [System.Collections.Generic.HashSet[string]]$TypeSet,
        [System.Collections.Generic.List[string]]$IssueList
    )

    if (-not (Test-Path $RootPath)) { return }

    $udtFiles = Get-ChildItem -Path $RootPath -Recurse -File -Filter "udts.json"
    foreach ($file in $udtFiles) {
        $parsed = $null
        try {
            $parsed = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        } catch {
            $IssueList.Add("$($file.FullName): invalid JSON while reading type definitions ($($_.Exception.Message))")
            continue
        }
        if (-not ($parsed -is [System.Array])) {
            continue
        }

        $prefix = Get-RelativeDirectoryPrefix -FilePath $file.FullName -RootPath $RootPath
        foreach ($row in $parsed) {
            if ($null -eq $row) { continue }
            if ((Has-Prop $row "tagType") -and ([string]$row.tagType -eq "UdtType") -and (Has-Prop $row "name") -and -not [string]::IsNullOrWhiteSpace([string]$row.name)) {
                $shortName = [string]$row.name
                $null = $TypeSet.Add($shortName)
                if ([string]::IsNullOrWhiteSpace($prefix)) {
                    $null = $TypeSet.Add($shortName)
                } else {
                    $null = $TypeSet.Add("$prefix/$shortName")
                }
            }
        }
    }
}

$resolvedInput = (Resolve-Path $ProviderPath).Path

$files = @()
if (Test-Path $resolvedInput -PathType Leaf) {
    $files = @((Get-Item $resolvedInput))
} else {
    $files = Get-ChildItem -Path $resolvedInput -Recurse -File -Filter *.json
}

if ($files.Count -eq 0) {
    throw "No JSON files found under: $resolvedInput"
}

$issues = New-Object System.Collections.Generic.List[string]
$typeReferences = New-Object System.Collections.Generic.List[pscustomobject]

foreach ($file in $files) {
    $parsed = $null
    try {
        $parsed = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
    } catch {
        $issues.Add("$($file.FullName): invalid JSON ($($_.Exception.Message))")
        continue
    }

    if (($file.Name -eq "udts.json") -or ($file.Name -eq "tags.json")) {
        if ($null -eq $parsed) {
            $issues.Add("$($file.FullName): $($file.Name) is null")
            continue
        }

        if (-not ($parsed -is [System.Array])) {
            $issues.Add("$($file.FullName): $($file.Name) must be a JSON array")
            continue
        }

        $rowIssues = Validate-TagRows -Rows @($parsed) -FilePath $file.FullName -NodePath $file.Name -ScopeParameters @() -StrictParamTokens:$StrictParameterTokens -TypeRefs $typeReferences
        foreach ($issue in $rowIssues) {
            $issues.Add($issue)
        }
    }
}

$definitionRootSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
if ($DefinitionRoots) {
    foreach ($root in $DefinitionRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        if (Test-Path $root) {
            $null = $definitionRootSet.Add((Resolve-Path $root).Path)
        } else {
            $issues.Add("Definition root not found: $root")
        }
    }
}

$tagDefinitionRoot = Get-ProviderScopedRoot -Path $resolvedInput -Segment "tag-definition"
if (-not [string]::IsNullOrWhiteSpace($tagDefinitionRoot)) {
    $typeRoot = $tagDefinitionRoot -replace "\\tag-definition\\", "\\tag-type-definition\\"
    if (Test-Path $typeRoot) {
        $null = $definitionRootSet.Add((Resolve-Path $typeRoot).Path)
    }
}

$tagTypeDefinitionRoot = Get-ProviderScopedRoot -Path $resolvedInput -Segment "tag-type-definition"
if (-not [string]::IsNullOrWhiteSpace($tagTypeDefinitionRoot) -and (Test-Path $tagTypeDefinitionRoot)) {
    $null = $definitionRootSet.Add((Resolve-Path $tagTypeDefinitionRoot).Path)
}

$knownTypeIds = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
foreach ($definitionRoot in $definitionRootSet) {
    Add-TypeIdsFromDefinitionRoot -RootPath $definitionRoot -TypeSet $knownTypeIds -IssueList $issues
}

if (($knownTypeIds.Count -gt 0) -and (-not $AllowUnknownTypeIds)) {
    foreach ($typeReference in $typeReferences) {
        if (-not $knownTypeIds.Contains($typeReference.TypeId)) {
            $issues.Add("$($typeReference.FilePath): $($typeReference.NodePath) references unknown typeId '$($typeReference.TypeId)'")
        }
    }
}

if ($issues.Count -gt 0) {
    Write-Output "Validation failed with $($issues.Count) issue(s):"
    foreach ($issue in $issues) {
        Write-Output "- $issue"
    }
    exit 1
}

Write-Output "Validation passed for $($files.Count) JSON file(s). Known typeIds loaded: $($knownTypeIds.Count)."
exit 0
