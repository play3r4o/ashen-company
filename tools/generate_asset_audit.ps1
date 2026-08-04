param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\.."),
    [string]$OutputPath = "artifacts\foundation_cleanup\asset_audit.csv"
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectRoot).Path
$output = Join-Path $project $OutputPath
$outputDirectory = Split-Path -Parent $output
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

Add-Type -AssemblyName System.Drawing
$textFiles = Get-ChildItem -Path $project -Recurse -File | Where-Object {
    $_.Extension -in ".gd", ".tscn", ".tres", ".json", ".cfg", ".md" -and
    $_.FullName -notmatch "\\\.godot\\|\\art\\archive\\"
}
$textCache = @{}
foreach ($file in $textFiles) {
    $textCache[$file.FullName] = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
}

$assets = Get-ChildItem -Path (Join-Path $project "assets") -Recurse -File | Where-Object {
    $_.Extension -in ".png", ".webp", ".jpg", ".jpeg", ".svg", ".ttf", ".otf", ".wav", ".ogg", ".mp3"
}
$hashGroups = $assets | Group-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
$duplicateCounts = @{}
foreach ($group in $hashGroups) { $duplicateCounts[$group.Name] = $group.Count }

$rows = foreach ($asset in $assets) {
    $relative = $asset.FullName.Substring($project.Length + 1).Replace("\", "/")
    $resPath = "res://$relative"
    $hash = (Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256).Hash
    $width = 0
    $height = 0
    if ($asset.Extension -in ".png", ".jpg", ".jpeg") {
        try {
            $image = [System.Drawing.Image]::FromFile($asset.FullName)
            $width = $image.Width
            $height = $image.Height
            $image.Dispose()
        } catch {}
    }
    $references = @()
    foreach ($entry in $textCache.GetEnumerator()) {
        if ($entry.Value -and $entry.Value.Contains($resPath)) {
            $references += $entry.Key.Substring($project.Length + 1).Replace("\", "/")
        }
    }
    $classification = if ($relative.StartsWith("assets/runtime/")) {
        "CANONICAL"
    } elseif ($references.Count -gt 0) {
        "LEGACY_REFERENCED"
    } elseif ($duplicateCounts[$hash] -gt 1) {
        "DUPLICATE"
    } else {
        "LEGACY_UNUSED"
    }
    [pscustomobject]@{
        path = $resPath
        width = $width
        height = $height
        sha256 = $hash
        import_file = if (Test-Path "$($asset.FullName).import") { "$resPath.import" } else { "" }
        referencing_files = ($references -join ";")
        duplicate_hash_count = $duplicateCounts[$hash]
        classification = $classification
        proposed_canonical_id = [IO.Path]::GetFileNameWithoutExtension($asset.Name)
        migration_status = if ($classification -eq "CANONICAL") { "STAGED" } else { "PENDING" }
        archive_status = if ($classification -eq "LEGACY_UNUSED") { "REVIEW" } else { "BLOCKED" }
    }
}

$rows | Sort-Object path | Export-Csv -LiteralPath $output -NoTypeInformation -Encoding UTF8
Write-Output "Wrote $($rows.Count) asset rows to $output"
