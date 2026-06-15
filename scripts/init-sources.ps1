param(
    [string]$Org     = "jumpserver",
    [string]$Version = ""
)

if (-not $Version) {
    if (Test-Path ".env") {
        $m = Select-String -Path ".env" -Pattern "^VERSION=(.+)$"
        if ($m) { $Version = $m.Matches[0].Groups[1].Value.Trim() }
    }
    if (-not $Version) { $Version = "v3.10.7" }
}

# repo-name -> local dir  (magnus removed - not a public repo)
$Repos = [ordered]@{
    "jumpserver" = "core"
    "lina"       = "lina"
    "luna"       = "luna"
    "koko"       = "koko"
    "lion"       = "lion"
    "chen"       = "chen"
}

New-Item -ItemType Directory -Force sources | Out-Null

foreach ($repo in $Repos.Keys) {
    $dest = "sources/$($Repos[$repo])"
    $url  = "https://github.com/$Org/$repo.git"

    if (Test-Path "$dest/.git") {
        Write-Host "==> Updating $dest ..." -ForegroundColor Cyan
        git -C $dest fetch origin
        git -C $dest checkout $Version
        continue
    }

    Write-Host "==> Cloning $url @ $Version => $dest ..." -ForegroundColor Cyan

    # try with version tag first, fall back to default branch
    git clone --depth 1 --branch $Version $url $dest 2>$null
    if (-not (Test-Path "$dest/.git")) {
        Write-Warning "Branch $Version not found for $repo, cloning default branch..."
        git clone --depth 1 $url $dest
    }
}

Write-Host ""
Write-Host "Done. sources/ ready." -ForegroundColor Green
