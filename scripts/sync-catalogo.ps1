<#
  Sincroniza el catálogo público de la tienda Área de Picnic (Tienda Nube)
  y regenera datos/snapshot-productos.json.

  - Lee los bloques JSON-LD (schema.org/Product) embebidos en la página
    pública /productos: nombre, precio, moneda, stock, disponibilidad, foto.
  - Escribe el snapshot solo si el catálogo cambió (evita commits vacíos).
  - Lo ejecuta GitHub Actions (.github/workflows/sync-catalogo.yml) cada
    30 minutos y a demanda; también se puede correr a mano:
        pwsh ./scripts/sync-catalogo.ps1
        powershell -ExecutionPolicy Bypass -File scripts/sync-catalogo.ps1
#>
param(
  [string]$Url = "https://tiendadeareadepicnic.mitiendanube.com/productos",
  [string]$Out = "datos/snapshot-productos.json",
  [switch]$Force
)
$ErrorActionPreference = "Stop"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

Write-Host "Descargando catálogo: $Url"
$resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0 (compatible; AreaDePicnicCRM-sync/1.0)" } -TimeoutSec 60
if ($resp.RawContentStream) { $html = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray()) } else { $html = [string]$resp.Content }
if (-not $html) { throw "Respuesta vacía de la tienda." }

$products = New-Object System.Collections.Generic.List[object]
$blocks = [regex]::Matches($html, "structured-data\.item[\s\S]*?</script>")
foreach ($m in $blocks) {
  $raw = $m.Value
  $start = $raw.IndexOf("{")
  if ($start -lt 0) { continue }
  $jsonText = $raw.Substring($start) -replace "</script>$", ""
  try { $j = $jsonText | ConvertFrom-Json } catch { continue }
  if (-not $j -or $j.'@type' -ne "Product" -or -not $j.offers -or -not $j.name) { continue }

  $id = ""
  if ($j.mainEntityOfPage -and $j.mainEntityOfPage.'@id') { $id = "" + $j.mainEntityOfPage.'@id' }
  $sm = [regex]::Match($id, "productos/([a-z0-9\-]+)/")
  if ($sm.Success) { $slug = $sm.Groups[1].Value } else { $slug = (("" + $j.name).ToLower() -replace "[^a-z0-9]+", "-").Trim("-") }

  $stock = $null
  if ($j.offers.inventoryLevel -and $null -ne $j.offers.inventoryLevel.value -and ("" + $j.offers.inventoryLevel.value) -ne "") { $stock = [int]$j.offers.inventoryLevel.value }
  $availability = "InStock"
  if (("" + $j.offers.availability) -match "OutOfStock") { $availability = "OutOfStock" }
  if ($null -ne $stock -and $stock -le 0) { $availability = "OutOfStock" }

  $pv = [double]$j.offers.price
  if ($pv -eq [math]::Floor($pv)) { $price = [long]$pv } else { $price = $pv }

  $image = $j.image
  if ($image -is [array]) { $image = $image[0] }
  $image = "" + $image

  $desc = "" + $j.description
  if ($desc.Length -gt 400) { $desc = $desc.Substring(0, 400) }

  $weight = $null
  if ($j.weight -and $null -ne $j.weight.value -and ("" + $j.weight.value) -ne "") { $weight = [double]$j.weight.value }

  $products.Add([ordered]@{
    slug = $slug
    name = "" + $j.name
    price = $price
    currency = if ($j.offers.priceCurrency) { "" + $j.offers.priceCurrency } else { "ARS" }
    stock = $stock
    availability = $availability
    image = $image
    description = $desc
    weight = $weight
    url = $id
  })
}

if ($products.Count -eq 0) { throw "No se encontraron productos (JSON-LD) en $Url. No se modifica el snapshot." }
Write-Host ("Productos leídos: {0}" -f $products.Count)
foreach ($p in $products) { Write-Host (" - {0} | {1} {2} | stock {3} | {4}" -f $p.name, $p.currency, $p.price, $p.stock, $p.availability) }

# Comparar con el snapshot anterior: solo se reescribe si cambió el catálogo.
$newProductsJson = ($products | ConvertTo-Json -Depth 6 -Compress)
$oldProductsJson = $null
if (Test-Path $Out) {
  try {
    $old = Get-Content -Path $Out -Raw -Encoding UTF8 | ConvertFrom-Json
    $oldList = if ($old -is [array]) { $old } else { $old.products }
    if ($oldList) { $oldProductsJson = ($oldList | ConvertTo-Json -Depth 6 -Compress) }
  } catch { $oldProductsJson = $null }
}
if (-not $Force -and $oldProductsJson -eq $newProductsJson) {
  Write-Host "Sin cambios en el catálogo. Snapshot intacto."
  exit 0
}

$doc = [ordered]@{
  updatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  source = $Url
  store = "tiendadeareadepicnic.mitiendanube.com"
  count = $products.Count
  products = $products
}
$json = $doc | ConvertTo-Json -Depth 6
$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $Out), ($json -replace "`r`n", "`n") + "`n", (New-Object System.Text.UTF8Encoding $false))
Write-Host "Snapshot actualizado: $Out"
