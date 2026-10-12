# 一条命令生成一个新软件站，可选直接上线。
#
# 用法：
#   powershell -NoProfile -File deploy\new-software.ps1 -Name myapp-site -Title "我的软件" -Description "一句话说明它解决什么"
#   powershell -NoProfile -File deploy\new-software.ps1 -Name myapp-site -Title "我的软件" -Description "..." -Publish
#
# 注意：本机只装了 Windows PowerShell（没有 pwsh），所以统一用 powershell 调用。
#
# 不带 -Publish：只在 outputs/ 下生成站点骨架并本地提交，方便先写内容。
# 带   -Publish：另外创建公开仓库、开启 Pages、推送，并把卡片登记到根站首页。

param(
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$Title = "",
  [string]$Description = "",
  [string]$Accent = "#4aa8ff",
  [switch]$Publish
)

$ErrorActionPreference = "Stop"
$hub = Split-Path $PSScriptRoot -Parent
$root = Split-Path $hub -Parent
$dest = Join-Path $root $Name

if ($Name -notmatch '^[a-z0-9][a-z0-9._-]*$') { throw "Name 只能用小写字母、数字、点、下划线、连字符" }
if (Test-Path -LiteralPath $dest) { throw "$dest 已存在，换个名字或先删掉它" }
if (-not $Title) { $Title = $Name }

function Write-Utf8NoBom([string]$Path, [string]$Text) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Get-Owner {
  $owner = (gh api user --jq .login) 2>&1
  if ($LASTEXITCODE -ne 0) { throw "gh 调用失败：$owner" }
  return $owner.Trim()
}

Write-Host "1/5 生成站点目录：$dest"
New-Item -ItemType Directory -Path $dest | Out-Null
New-Item -ItemType Directory -Path (Join-Path $dest "deploy") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $dest ".github\workflows") | Out-Null

# 设计系统共用根站那一份，避免每个站各改一套
Copy-Item -LiteralPath (Join-Path $hub "styles.css") -Destination (Join-Path $dest "styles.css")
Copy-Item -LiteralPath (Join-Path $hub "template\app.js") -Destination (Join-Path $dest "app.js")
Copy-Item -LiteralPath (Join-Path $hub "template\workflow-deploy-pages.yml") -Destination (Join-Path $dest ".github\workflows\deploy-pages.yml")
Copy-Item -LiteralPath (Join-Path $hub "template\publish.ps1") -Destination (Join-Path $dest "deploy\publish-github.ps1")

Write-Host "2/5 写入页面骨架"
$html = Get-Content -Raw -LiteralPath (Join-Path $hub "template\index.html")
$html = $html.Replace("{{TITLE}}", $Title).Replace("{{DESC}}", $Description).Replace("{{NAME}}", $Name)
Write-Utf8NoBom (Join-Path $dest "index.html") $html

$readme = @"
# $Title

$Description

纯静态站点，零依赖，不需要构建。本地预览直接双击 `index.html`。

## 上线

``````powershell
powershell -NoProfile -File deploy\publish-github.ps1
``````

发布后地址形如 ``https://<你的用户名>.github.io/$Name/``，每次 ``git push`` 自动重新部署。
"@
Write-Utf8NoBom (Join-Path $dest "README.md") $readme

Write-Host "3/5 初始化仓库并提交"
Push-Location $dest
try {
  git init -b main | Out-Null
  git add -A
  git commit -q -m "$Title`: 站点骨架" | Out-Null
} finally {
  Pop-Location
}

$owner = ""
if ($Publish) {
  $owner = Get-Owner
  Write-Host "4/5 创建仓库并上线：$owner/$Name"
  Push-Location $dest
  try {
    gh repo create $Name --public --source . --remote origin --push 2>&1 | Out-Null
    gh api -X POST "repos/$owner/$Name/pages" -f "build_type=workflow" 2>&1 | Out-Null
    gh workflow run deploy-pages.yml --repo "$owner/$Name" 2>&1 | Out-Null
  } finally {
    Pop-Location
  }
} else {
  Write-Host "4/5 跳过上线（未指定 -Publish）"
}

Write-Host "5/5 登记到根站首页"
$projectsPath = Join-Path $hub "projects.js"
$projects = Get-Content -Raw -LiteralPath $projectsPath
$safeDesc = $Description.Replace("'", "\'")
$safeTitle = $Title.Replace("'", "\'")
$entry = @"
  {
    name: '$Name',
    title: '$safeTitle',
    desc: '$safeDesc',
    dot: '$Accent',
    tags: [],
    status: 'live',
    repo: 'https://github.com/$owner/$Name'
  }
"@
$marker = "`n  // NEW-ENTRIES-HERE"
if (-not $projects.Contains($marker)) { throw "projects.js 里找不到登记位置标记，请手工添加条目" }
$projects = $projects.Replace($marker, ",`n" + $entry + $marker)
Write-Utf8NoBom $projectsPath $projects

if ($Publish) {
  Push-Location $hub
  try {
    git add -A
    git commit -q -m "登记新软件：$Title" | Out-Null
    git push -q origin main
    Write-Host "根站已更新，首页马上会多一张卡片。"
  } finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "完成。"
Write-Host "  站点目录: $dest"
if ($Publish) {
  Write-Host "  仓库: https://github.com/$owner/$Name"
  Write-Host "  站点: https://$owner.github.io/$Name/  (约 1 分钟后生效)"
} else {
  Write-Host "  写好内容后执行: powershell -NoProfile -File deploy\publish-github.ps1"
}
