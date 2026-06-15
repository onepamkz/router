param(
    [Parameter(Mandatory)]
    [string]$Org
)

$Map = [ordered]@{
    "core"   = "core"
    "lina"   = "proxy"
    "luna"   = "atlas"
    "koko"   = "gateway"
    "lion"   = "switch"
    "chen"   = "relay"
}

foreach ($local in $Map.Keys) {
    $remote = $Map[$local]
    $path   = "sources\$local"
    $url    = "https://github.com/$Org/$remote.git"

    if (-not (Test-Path "$path")) {
        Write-Warning "sources\$local not found - skipping"
        continue
    }

    Write-Host "==> $local -> $url" -ForegroundColor Cyan

    Remove-Item "$path\.git" -Recurse -Force -ErrorAction SilentlyContinue
    git -C $path init -b main
    git -C $path add .
    git -C $path commit -m "init"
    git -C $path remote add origin $url
    git -C $path push -u origin main --force

    Write-Host "    done" -ForegroundColor Green
}

Write-Host "All repos pushed to github.com/$Org/" -ForegroundColor Green
