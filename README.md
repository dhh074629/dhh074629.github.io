# 软件索引（根站）

这是所有软件的统一入口。仓库名必须是 `<用户名>.github.io`，站点才会独占域名根路径
（这里是 `https://dhh074629.github.io/`），其他软件仓库自动落到各自的 `/<仓库名>/`。

```
index.html                    首页：卡片式列出所有软件
projects.js                   登记表 —— 加一个软件就在这个数组里加一条
app.js                        把登记表渲染成卡片
styles.css                    统一设计系统，所有软件站共用这一份
template/                     新软件站的骨架模板
deploy/publish-github.ps1     发布根站
deploy/new-software.ps1       一条命令生成 + 上线一个新软件站
.github/workflows/            推送即自动部署
```

本地预览：直接双击 `index.html`。

## 加一个新软件

```powershell
cd outputs/lab-hub
powershell -NoProfile -File deploy\new-software.ps1 -Name myapp-site -Title "我的软件" -Description "一句话说明" -Publish
```

脚本做的事：在 `outputs/` 下新建 `myapp-site/`（复制设计系统与骨架）、替换标题与描述占位符、
初始化 git 并提交、创建公开仓库、开启 Pages、推送、把新条目插进 `projects.js`，
最后可选地把根站的更新也推上去，首页立刻多一张卡片。

不带 `-Publish` 时只做本地生成，适合"先把内容写好再上线"。

## 维护约定

- 改设计：只改 `styles.css`，然后复制到各软件站（或直接在各站改，注意保持一致）。
- 下架某个软件：把 `projects.js` 里那条注释掉或删掉即可，仓库本身不受影响；真不要了再把仓库归档。
- 速度：GitHub Pages 在国内偶发慢。需要更快就接 Cloudflare Pages（连仓库，自动部署）或国内 OSS+CDN（快，但绑域名要 ICP 备案）。
