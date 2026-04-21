[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectViewsRoot,
    [Parameter(Mandatory = $true)]
    [string]$ViewPath,
    [string]$UdtType = "",
    [string]$Title = "UDT Faceplate",
    [int]$Width = 820,
    [int]$Height = 420,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$segments = $ViewPath.Trim().Trim('/','\') -split "[/\\]+" | Where-Object { $_ -and $_.Trim().Length -gt 0 }
if ($segments.Count -eq 0) {
    throw "ViewPath cannot be empty."
}

$viewDir = $ProjectViewsRoot
foreach ($segment in $segments) {
    $viewDir = Join-Path $viewDir $segment
}
$viewJsonPath = Join-Path $viewDir "view.json"
$resourceJsonPath = Join-Path $viewDir "resource.json"

if ((Test-Path $viewJsonPath) -and -not $Force) {
    throw "View already exists: $viewJsonPath (use -Force to overwrite)."
}

$view = [ordered]@{
    custom = [ordered]@{}
    params = [ordered]@{
        tagPath = ""
        title = $Title
    }
    propConfig = [ordered]@{
        "params.tagPath" = [ordered]@{
            paramDirection = "input"
            persistent = $true
        }
        "params.title" = [ordered]@{
            paramDirection = "input"
            persistent = $true
        }
    }
    props = [ordered]@{
        defaultSize = [ordered]@{
            width = $Width
            height = $Height
        }
    }
    root = [ordered]@{
        type = "ia.container.flex"
        version = 0
        props = [ordered]@{
            direction = "column"
            style = [ordered]@{
                padding = "10px"
                gap = "8px"
                backgroundColor = "#0f172a"
                border = "1px solid #334155"
            }
        }
        meta = [ordered]@{
            name = "root"
        }
        position = [ordered]@{}
        children = @(
            [ordered]@{
                type = "ia.container.flex"
                version = 0
                meta = [ordered]@{ name = "header" }
                position = [ordered]@{
                    basis = "64px"
                    shrink = 0
                }
                props = [ordered]@{
                    justify = "space-between"
                    alignItems = "center"
                    style = [ordered]@{
                        backgroundColor = "#1e293b"
                        border = "1px solid #334155"
                        padding = "10px"
                        gap = "10px"
                    }
                }
                children = @(
                    [ordered]@{
                        type = "ia.display.label"
                        version = 0
                        meta = [ordered]@{ name = "title-label" }
                        position = [ordered]@{
                            basis = "40%"
                            grow = 1
                        }
                        propConfig = [ordered]@{
                            "props.text" = [ordered]@{
                                binding = [ordered]@{
                                    type = "property"
                                    config = [ordered]@{ path = "view.params.title" }
                                }
                            }
                        }
                        props = [ordered]@{
                            text = $Title
                            style = [ordered]@{
                                color = "#e2e8f0"
                                fontSize = "20px"
                                fontWeight = "700"
                            }
                        }
                    }
                    [ordered]@{
                        type = "ia.display.label"
                        version = 0
                        meta = [ordered]@{ name = "tag-path-badge" }
                        position = [ordered]@{
                            basis = "60%"
                            grow = 1
                        }
                        propConfig = [ordered]@{
                            "props.text" = [ordered]@{
                                binding = [ordered]@{
                                    type = "property"
                                    config = [ordered]@{ path = "view.params.tagPath" }
                                }
                            }
                        }
                        props = [ordered]@{
                            text = "[provider]instance"
                            style = [ordered]@{
                                color = "#93c5fd"
                                border = "1px solid #3b82f6"
                                padding = "6px 10px"
                                textAlign = "right"
                                fontFamily = "Consolas, monospace"
                            }
                        }
                    }
                )
            },
            [ordered]@{
                type = "ia.container.flex"
                version = 0
                meta = [ordered]@{ name = "body" }
                position = [ordered]@{
                    grow = 1
                }
                props = [ordered]@{
                    gap = "10px"
                    style = [ordered]@{
                        overflow = "hidden"
                    }
                }
                children = @(
                    [ordered]@{
                        type = "ia.container.flex"
                        version = 0
                        meta = [ordered]@{ name = "instance-info-card" }
                        position = [ordered]@{
                            basis = "280px"
                            grow = 0
                            shrink = 0
                        }
                        props = [ordered]@{
                            direction = "column"
                            gap = "8px"
                            style = [ordered]@{
                                backgroundColor = "#1e293b"
                                border = "1px solid #334155"
                                padding = "10px"
                            }
                        }
                        children = @(
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "instance-header" }
                                position = [ordered]@{ basis = "30px" }
                                props = [ordered]@{
                                    text = "UDT Instance"
                                    style = [ordered]@{
                                        color = "#e2e8f0"
                                        fontWeight = "600"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "instance-path" }
                                position = [ordered]@{ basis = "40px" }
                                propConfig = [ordered]@{
                                    "props.text" = [ordered]@{
                                        binding = [ordered]@{
                                            type = "property"
                                            config = [ordered]@{ path = "view.params.tagPath" }
                                        }
                                    }
                                }
                                props = [ordered]@{
                                    text = "[provider]instance"
                                    style = [ordered]@{
                                        color = "#bfdbfe"
                                        fontFamily = "Consolas, monospace"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "drop-help" }
                                position = [ordered]@{
                                    grow = 1
                                }
                                props = [ordered]@{
                                    text = "Drop a matching UDT instance onto this view in Designer to set tagPath."
                                    style = [ordered]@{
                                        color = "#cbd5e1"
                                        whiteSpace = "normal"
                                    }
                                }
                            }
                        )
                    },
                    [ordered]@{
                        type = "ia.container.flex"
                        version = 0
                        meta = [ordered]@{ name = "level-card" }
                        position = [ordered]@{
                            grow = 1
                        }
                        props = [ordered]@{
                            direction = "column"
                            gap = "8px"
                            style = [ordered]@{
                                backgroundColor = "#1e293b"
                                border = "1px solid #334155"
                                padding = "10px"
                            }
                        }
                        children = @(
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "level-header" }
                                position = [ordered]@{ basis = "30px" }
                                props = [ordered]@{
                                    text = "Level (example member)"
                                    style = [ordered]@{
                                        color = "#e2e8f0"
                                        fontWeight = "600"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "level-value" }
                                position = [ordered]@{ basis = "60px" }
                                propConfig = [ordered]@{
                                    "props.text" = [ordered]@{
                                        binding = [ordered]@{
                                            type = "tag"
                                            config = [ordered]@{
                                                mode = "indirect"
                                                fallbackDelay = 2.5
                                                references = [ordered]@{
                                                    base = "{view.params.tagPath}"
                                                }
                                                tagPath = "{base}/Level"
                                            }
                                            transforms = @(
                                                [ordered]@{
                                                    type = "expression"
                                                    expression = 'try(numberFormat(toFloat({value}), "#,##0.###"), "n/a")'
                                                }
                                            )
                                        }
                                    }
                                }
                                props = [ordered]@{
                                    text = "n/a"
                                    style = [ordered]@{
                                        color = "#86efac"
                                        fontSize = "30px"
                                        fontWeight = "700"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "level-member-path" }
                                position = [ordered]@{
                                    grow = 1
                                }
                                propConfig = [ordered]@{
                                    "props.text" = [ordered]@{
                                        binding = [ordered]@{
                                            type = "expr"
                                            config = [ordered]@{
                                                expression = '"Member path: " + {view.params.tagPath} + "/Level"'
                                            }
                                        }
                                    }
                                }
                                props = [ordered]@{
                                    text = "Member path: [provider]instance/Level"
                                    style = [ordered]@{
                                        color = "#94a3b8"
                                        fontFamily = "Consolas, monospace"
                                        whiteSpace = "normal"
                                    }
                                }
                            }
                        )
                    },
                    [ordered]@{
                        type = "ia.container.flex"
                        version = 0
                        meta = [ordered]@{ name = "status-card" }
                        position = [ordered]@{
                            basis = "220px"
                            shrink = 0
                        }
                        props = [ordered]@{
                            direction = "column"
                            gap = "8px"
                            style = [ordered]@{
                                backgroundColor = "#1e293b"
                                border = "1px solid #334155"
                                padding = "10px"
                            }
                        }
                        children = @(
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "out1-header" }
                                position = [ordered]@{ basis = "30px" }
                                props = [ordered]@{
                                    text = "OUT1 (example member)"
                                    style = [ordered]@{
                                        color = "#e2e8f0"
                                        fontWeight = "600"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "out1-value" }
                                position = [ordered]@{ basis = "60px" }
                                propConfig = [ordered]@{
                                    "props.text" = [ordered]@{
                                        binding = [ordered]@{
                                            type = "tag"
                                            config = [ordered]@{
                                                mode = "indirect"
                                                fallbackDelay = 2.5
                                                references = [ordered]@{
                                                    base = "{view.params.tagPath}"
                                                }
                                                tagPath = "{base}/Out1"
                                            }
                                            transforms = @(
                                                [ordered]@{
                                                    type = "map"
                                                    inputType = "scalar"
                                                    outputType = "scalar"
                                                    fallback = "UNKNOWN"
                                                    mappings = @(
                                                        [ordered]@{ input = $true; output = "ON" },
                                                        [ordered]@{ input = $false; output = "OFF" }
                                                    )
                                                }
                                            )
                                        }
                                    }
                                }
                                props = [ordered]@{
                                    text = "UNKNOWN"
                                    style = [ordered]@{
                                        color = "#fcd34d"
                                        fontSize = "28px"
                                        fontWeight = "700"
                                        textAlign = "center"
                                    }
                                }
                            },
                            [ordered]@{
                                type = "ia.display.label"
                                version = 0
                                meta = [ordered]@{ name = "out1-member-path" }
                                position = [ordered]@{
                                    grow = 1
                                }
                                propConfig = [ordered]@{
                                    "props.text" = [ordered]@{
                                        binding = [ordered]@{
                                            type = "expr"
                                            config = [ordered]@{
                                                expression = '"Member path: " + {view.params.tagPath} + "/Out1"'
                                            }
                                        }
                                    }
                                }
                                props = [ordered]@{
                                    text = "Member path: [provider]instance/Out1"
                                    style = [ordered]@{
                                        color = "#94a3b8"
                                        fontFamily = "Consolas, monospace"
                                        whiteSpace = "normal"
                                    }
                                }
                            }
                        )
                    }
                )
            }
        )
    }
}

if (-not [string]::IsNullOrWhiteSpace($UdtType)) {
    $view.props.dropConfig = [ordered]@{
        udts = @(
            [ordered]@{
                action = "path"
                param = "tagPath"
                type = $UdtType
            }
        )
    }
}

$resource = [ordered]@{
    scope = "G"
    version = 1
    restricted = $false
    overridable = $true
    files = @("view.json")
}

New-Item -ItemType Directory -Path $viewDir -Force | Out-Null
($view | ConvertTo-Json -Depth 100) | Set-Content -Path $viewJsonPath -Encoding UTF8
($resource | ConvertTo-Json -Depth 20) | Set-Content -Path $resourceJsonPath -Encoding UTF8

Write-Output "Created faceplate view: $viewJsonPath"
