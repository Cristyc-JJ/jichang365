param(
    [switch]$Submit,
    [string]$SitemapPath = (Join-Path (Get-Location) "sitemap.xml")
)

$ErrorActionPreference = "Stop"
$key = "012d4e118ee74f9f8d5a08cc336699de"
$hostName = "yunguidaohang.com"
$keyFile = Join-Path (Get-Location) "$key.txt"
$keyLocation = "https://$hostName/$key.txt"
$endpoint = "https://api.indexnow.org/indexnow"
$logPath = Join-Path (Get-Location) "indexnow-submit.log"

if (-not (Test-Path $SitemapPath)) {
    throw "sitemap.xml not found: $SitemapPath"
}
if (-not (Test-Path $keyFile)) {
    throw "IndexNow key file not found: $keyFile"
}
if ((Get-Content $keyFile -Raw -Encoding UTF8).Trim() -ne $key) {
    throw "IndexNow key file content does not match the configured key."
}

[xml]$sitemapXml = Get-Content $SitemapPath -Raw -Encoding UTF8
$urls = @($sitemapXml.urlset.url.loc) |
    ForEach-Object { [string]$_ } |
    Where-Object { $_ -match '^https://yunguidaohang\.com/' } |
    Sort-Object -Unique

if ($urls.Count -eq 0) {
    throw "No canonical yunguidaohang.com URLs found in sitemap.xml."
}

Write-Host "IndexNow configuration validated." -ForegroundColor Green
Write-Host "Host: $hostName"
Write-Host "Key location: $keyLocation"
Write-Host "Canonical URLs ready: $($urls.Count)"

if (-not $Submit) {
    Write-Host "Preview only. Deploy the key file first, then run:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\submit_indexnow.ps1 -Submit"
    exit 0
}

$liveKey = Invoke-WebRequest -Uri $keyLocation -UseBasicParsing -TimeoutSec 20
if ($liveKey.StatusCode -ne 200 -or $liveKey.Content.Trim() -ne $key) {
    throw "The live key file is not available or does not match: $keyLocation"
}

$batchSize = 10000
for ($offset = 0; $offset -lt $urls.Count; $offset += $batchSize) {
    $last = [Math]::Min($offset + $batchSize - 1, $urls.Count - 1)
    $batch = @($urls[$offset..$last])
    $payload = @{
        host = $hostName
        key = $key
        keyLocation = $keyLocation
        urlList = $batch
    } | ConvertTo-Json -Depth 4

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        $response = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload -ContentType "application/json; charset=utf-8" -UserAgent "Yunguidaohang-IndexNow/2.0" -TimeoutSec 30
        $line = "$stamp SUCCESS status=$($response.StatusCode) urls=$($batch.Count)"
        Add-Content -Path $logPath -Value $line -Encoding UTF8
        Write-Host $line -ForegroundColor Green
    } catch {
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { "network-error" }
        $line = "$stamp FAILED status=$status urls=$($batch.Count) message=$($_.Exception.Message)"
        Add-Content -Path $logPath -Value $line -Encoding UTF8
        throw $line
    }
}

Write-Host "IndexNow submission finished. Log: $logPath" -ForegroundColor Green
