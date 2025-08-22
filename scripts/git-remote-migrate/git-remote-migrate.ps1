#Requires -Version 5.1
$ErrorActionPreference = "Stop"

########## EDIT ME ##########
$OldHost = "oldgithost.com"
$NewHost = "newgithost.com"
$Root    = "$env:USERPROFILE\repos"  # where to start scanning for repos
$DryRun  = $true                    # set to $true to preview changes
######## END EDIT ME ########

Get-ChildItem -Path $Root -Recurse -Directory -Filter ".git" | ForEach-Object {
  $repo = $_.Parent.FullName
  Push-Location $repo
  try {
    $url = git remote get-url origin 2>$null
    if (-not $url) { return }
    if ($url -notlike "*$OldHost*") { return }

    $newUrl = $null

    # scp-like: user@host:path
    if ($url -match '^(?<user>[^@/:]+)@(?<host>[^:]+):(?<path>.+)$') {
      $user = $Matches.user; $host = $Matches.host; $path = $Matches.path
      if ($host -eq $OldHost) { $newUrl = "$user@$NewHost:$path" }
    }
    elseif ($url -match '^[a-z][a-z0-9+\-.]*://') {
      try {
        $u = [uri]$url
        $userInfo = if ($u.UserInfo) { "$($u.UserInfo)@" } else { "" }
        $portPart = if ($u.IsDefaultPort) { "" } else { ":$($u.Port)" }
        if ($u.Host -eq $OldHost) {
          $newUrl = "{0}://{1}{2}{3}{4}" -f $u.Scheme, $userInfo, $NewHost, $portPart, $u.PathAndQuery
        }
      } catch {
        $newUrl = $url -replace [regex]::Escape($OldHost), $NewHost, 1
      }
    }

    if (-not $newUrl) {
      $newUrl = $url -replace [regex]::Escape($OldHost), $NewHost, 1
    }

    if ($newUrl -and $newUrl -ne $url) {
      Write-Host "✔ $repo"
      Write-Host "    $url"
      Write-Host " -> $newUrl"
      if (-not $DryRun) {
        git remote set-url origin $newUrl
      }
    }
  } finally {
    Pop-Location
  }
}

# Optional safety net (uncomment to enable):
# git config --global url.("https://$NewHost/").insteadOf ("https://$OldHost/")
# git config --global url.("ssh://git@$NewHost/").insteadOf ("ssh://git@$OldHost/")

