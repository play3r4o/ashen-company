param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$runtimeRoot = Join-Path $ProjectRoot 'assets\runtime'
$manifestPath = Join-Path $runtimeRoot 'asset_manifest.json'
$referenceFiles = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'scenes') -Recurse -File |
    Where-Object { $_.Extension -in '.tscn', '.tres', '.gd' }
$references = @{}
foreach ($referenceFile in $referenceFiles) {
    $text = Get-Content -LiteralPath $referenceFile.FullName -Raw
    foreach ($match in [regex]::Matches($text, 'res://assets/runtime/[A-Za-z0-9_./-]+')) {
        $path = $match.Value.TrimEnd('"', "'", ')', ']', '}')
        if (-not $references.ContainsKey($path)) { $references[$path] = @() }
        $owner = 'res://' + $referenceFile.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/').Replace('\', '/')
        if ($owner -notin $references[$path]) { $references[$path] += $owner }
    }
}

$existingByPath = @{}
if (Test-Path -LiteralPath $manifestPath) {
    $parsed = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($null -ne $parsed.assets) {
        foreach ($property in $parsed.assets.psobject.Properties) {
            $existingRecord = $property.Value
            if ($null -ne $existingRecord.path) { $existingByPath[[string]$existingRecord.path] = $existingRecord }
        }
    }
}

$assets = [ordered]@{}
$files = Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File |
    Where-Object { $_.Name -ne 'asset_manifest.json' -and $_.Extension -notin '.import', '.uid' } |
    Sort-Object FullName
foreach ($file in $files) {
    $relative = $file.FullName.Substring($runtimeRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $path = 'res://assets/runtime/' + $relative
    $stableId = [IO.Path]::ChangeExtension($relative, $null) -replace '[^A-Za-z0-9]+', '_'
    $record = [ordered]@{
        path = $path
        category = ($relative -split '/')[0]
        kind = if ($file.Extension -eq '.png') { 'texture' } elseif ($file.Extension -in '.wav', '.ogg', '.mp3') { 'audio' } elseif ($file.Extension -in '.ttf', '.otf') { 'font' } else { 'resource' }
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        version = 1
    }
    if ($file.Extension -eq '.png') {
        $image = [System.Drawing.Image]::FromFile($file.FullName)
        try { $record.size = @($image.Width, $image.Height) } finally { $image.Dispose() }
        $record.filter = 'nearest'
        $record.expected_alpha = $true
    }
    if ($references.ContainsKey($path)) { $record.owner_scenes = @($references[$path] | Sort-Object) }
    else { $record.owner_scenes = @() }
    $priorRecord = if ($existingByPath.ContainsKey($path)) { $existingByPath[$path] } else { $null }
    if ($null -ne $priorRecord) {
        foreach ($key in @('frame_size', 'frames', 'fps', 'nine_slice_margins', 'repeat_mode')) {
            $property = $priorRecord.psobject.Properties[$key]
            if ($null -ne $property) { $record[$key] = $property.Value }
        }
        if ($null -ne $priorRecord.kind) { $record.kind = $priorRecord.kind }
    }
	# Approval provenance is a stable state, never a loadable source-art path.
	# Source files live under res://art/ and are deliberately excluded from exports.
	$record.approval = 'approved'
    $assets[$stableId] = $record
}

$manifest = [ordered]@{ schema_version = 1; generated_by = 'tools/generate_runtime_manifest.ps1'; assets = $assets }
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output "Wrote $($assets.Count) canonical runtime asset records to $manifestPath"
