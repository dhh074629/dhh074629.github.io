# 发布当前软件站到 GitHub Pages。
# 前提：本机 gh 已登录，且当前目录已经是 git 仓库。
param([string]$Repo = "")

$ErrorActionPreference = "Stop"
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  gh auth status 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "gh 还没登录，先跑 gh auth login" }

  $owner = (gh api user --jq .login).Trim()
  if (-not $Repo) { $Repo = Split-Path (Get-Location) -Leaf }

  if (-not (Test-Path .git)) {
    git init -b main | Out-Null
    git add -A
    git commit -m "站点初始化" | Out-Null
  }

  gh repo view "$owner/$Repo" 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) {
    if (-not (git remote)) { git remote add origin "https://github.com/$owner/$Repo.git" }
    git push -u origin main
  } else {
    gh repo create $Repo --public --source . --remote origin --push
  }

  gh api -X POST "repos/$owner/$Repo/pages" -f "build_type=workflow" 2>&1 | Out-Null

  "仓库: https://github.com/$owner/$Repo"
  "站点: https://$owner.github.io/$Repo/  （约 1 分钟后生效）"
} finally {
  Pop-Location
}
