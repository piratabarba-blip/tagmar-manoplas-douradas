param([switch]$ValidarSomente)
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$roles = @('Arrow','Help','AppStarting','Wait','Crosshair','IBeam','NWPen','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll','UpArrow','Hand','Pin','Person')
foreach ($size in @(48,64)) {
    foreach ($role in $roles) {
        $entries = @($manifest | Where-Object { $_.size -eq $size -and $_.role -eq $role })
        if ($entries.Count -ne 1) { throw "Entrada ausente ou duplicada: $role / $size" }
        $relative = [string]$entries[0].file
        if ($relative -notmatch '^(48|64)px/[A-Za-z0-9_]+\.(ani|cur)$') { throw 'Nome de arquivo inesperado.' }
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $relative) -PathType Leaf)) { throw "Arquivo ausente: $relative" }
    }
}
if ($ValidarSomente) { Write-Host 'OK: dois esquemas completos, 17 funcoes por esquema e arquivos presentes.'; exit 0 }

$destination = Join-Path $env:LOCALAPPDATA 'Tagmar\Cursores\ManoplasDouradas-v1'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
foreach ($size in @(48,64)) {
    $target = Join-Path $destination ($size.ToString() + 'px')
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    foreach ($entry in @($manifest | Where-Object { $_.size -eq $size })) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $entry.file) -Destination $target -Force
    }
}
$registryPath = 'HKCU:\Control Panel\Cursors\Schemes'
if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
$backupPath = Join-Path $destination 'esquemas-anteriores.json'
if (-not (Test-Path -LiteralPath $backupPath)) {
    $backup = @{}
    foreach ($size in @(48,64)) {
        $name = "Tagmar - Manoplas Douradas ($($size)px)"
        $value = (Get-Item -LiteralPath $registryPath).GetValue($name, $null)
        $backup[$name] = $value
    }
    $backup | ConvertTo-Json | Set-Content -LiteralPath $backupPath -Encoding UTF8
}
foreach ($size in @(48,64)) {
    $paths = foreach ($role in $roles) {
        $entry = $manifest | Where-Object { $_.size -eq $size -and $_.role -eq $role }
        Join-Path $destination ($entry.file.Replace('/', '\'))
    }
    $name = "Tagmar - Manoplas Douradas ($($size)px)"
    New-ItemProperty -LiteralPath $registryPath -Name $name -PropertyType String -Value ($paths -join ',') -Force | Out-Null
}
Write-Host 'Pronto! Os dois esquemas Tagmar foram cadastrados.' -ForegroundColor Green
Write-Host 'Na aba Ponteiros, escolha Tagmar - Manoplas Douradas (48px ou 64px) e clique Aplicar.'
Write-Host 'O esquema atual foi preservado. A mao aberta esta na pasta como opcao extra.'
Start-Process -FilePath "$env:SystemRoot\System32\control.exe" -ArgumentList 'main.cpl,,1'
