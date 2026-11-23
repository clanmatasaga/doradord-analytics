# Instalador de recursos locales FFmpeg para DoradoRD Analytics
# Ejecutar desde la raíz del repositorio clanmatasaga/doradord-analytics.
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$ffDir = Join-Path $root 'ffmpeg'
New-Item -ItemType Directory -Force -Path $ffDir | Out-Null


function Download-Checked($url, $destination) {
  Write-Host "Descargando $([System.IO.Path]::GetFileName($destination)) ..."
  Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
  if (!(Test-Path $destination) -or (Get-Item $destination).Length -lt 100) {
    throw "Descarga incompleta: $destination"
  }
}

$pkg = 'https://unpkg.com/@ffmpeg/ffmpeg@0.12.10/dist/esm'
$core = 'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.6/dist/umd'
# ESM worker plus sibling imports required by the worker package.
Download-Checked "$pkg/worker.js" (Join-Path $ffDir 'worker.js')
Download-Checked "$pkg/const.js" (Join-Path $ffDir 'const.js')
Download-Checked "$pkg/errors.js" (Join-Path $ffDir 'errors.js')
Download-Checked "$pkg/utils.js" (Join-Path $ffDir 'utils.js')
Download-Checked "$pkg/types.js" (Join-Path $ffDir 'types.js')
# FFmpeg core single-thread files (matched to ffmpeg package v0.12.10 release line).
Download-Checked "$core/ffmpeg-core.js" (Join-Path $ffDir 'ffmpeg-core.js')
Download-Checked "$core/ffmpeg-core.wasm" (Join-Path $ffDir 'ffmpeg-core.wasm')

# Make the existing index point to local core assets and matched core version.
$index = Join-Path $root 'index.html'
if (Test-Path $index) {
  $html = Get-Content -Raw -Path $index
  $old = 'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.10/dist/umd'
  $new = './ffmpeg'
  if ($html.Contains($old)) {
    $html = $html.Replace($old, $new)
    Set-Content -Path $index -Value $html -Encoding UTF8
    Write-Host 'index.html actualizado: core local ./ffmpeg.'
  } elseif ($html.Contains('const coreBase =')) {
    # If the exact CDN line is different, do not make a broad/unsafe edit.
    Write-Warning 'No se reconoció la URL esperada de coreBase. Revisa la línea coreBase manualmente.'
  }
} else {
  Write-Warning 'No encontré index.html. Ejecuta este script desde la raíz del repositorio.'
}
Write-Host ''
Write-Host 'Instalación de archivos FFmpeg terminada.' -ForegroundColor Green
Write-Host 'Verifica que la carpeta ffmpeg/ contiene worker.js, const.js, errors.js, utils.js, types.js, ffmpeg-core.js y ffmpeg-core.wasm.'
Write-Host 'Luego revisa los cambios y haz commit/push desde GitHub.'
