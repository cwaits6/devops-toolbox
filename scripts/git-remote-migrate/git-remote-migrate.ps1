#Requires -Version 5.1
$ErrorActionPreference = "Stop"

#========= EDIT ME =========#
$OldHost = "oldgithost.com"
$NewHost = "newgithost.com"
$Root    = "$env:USERPROFILE\repos"  # where to start scanning for repos
$DryRun  = $true                     # set $false to apply changes
#======= END EDIT ME =======#

Get-ChildItem -Path $Root -Recurse -Directory -Filter ".git" | ForEach-Object {
  $repo = $_.Parent.FullName
  Push-Location $repo
  try {
    $url = git remote get-url origin 2>$null
    if (-not $url) { continue }
    if ($url -notlike "*$OldHost*") { continue }

    $newUrl = $null  # reset per-repo

    # scp-like: user@host:path
    if ($url -match '^(?<user>[^@/:]+)@(?<host>[^:]+):(?<path>.+)$') {
      if ($Matches.host -eq $OldHost) {
        $newUrl = "$($Matches.user)@$NewHost:$($Matches.path)"
      }
    }
    # scheme URLs: scheme://[userinfo@]host[:port]/path
    elseif ($url -match '^[a-z][a-z0-9+\-.]*://') {
      try {
        $u = [uri]$url
        if ($u.Host -eq $OldHost) {
          $userInfo = if ($u.UserInfo) { "$($u.UserInfo)@" } else { "" }
          $portPart = if ($u.IsDefaultPort) { "" } else { ":$($u.Port)" }
          $newUrl   = "{0}://{1}{2}{3}{4}" -f $u.Scheme, $userInfo, $NewHost, $portPart, $u.PathAndQuery
        }
      } catch {
        # unknown/invalid URI style → skip (no fallback)
      }
    }

    if ($newUrl -and $newUrl -ne $url) {
      Write-Host "✔ $repo"
      Write-Host "    $url"
      Write-Host " -> $newUrl"
      Write-Host ""
      if (-not $DryRun) {
        git remote set-url origin $newUrl
      }
    }
  }
  finally {
    Pop-Location
  }
}

# Optional safety net (uncomment to enable):
# git config --global url.("https://$NewHost/").insteadOf ("https://$OldHost/")
# git config --global url.("ssh://git@$NewHost/").insteadOf ("ssh://git@$OldHost/")

