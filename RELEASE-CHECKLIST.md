# 发布前检查清单

## 已完成

- [x] 发布目录不包含测试者的 `reading-time.tsv`、生成数据、日志、状态文件或数据库备份。
- [x] 仓库内的 `data.js` 是空白启动数据，不含书名、书籍 ID 或阅读记录。
- [x] 当前 Kindle 上使用的启动器、计时服务、数据生成器和页面文件已复制到发布目录，并统一改为正式路径。
- [x] Shell 脚本通过语法检查，且使用 LF 换行、无 UTF-8 BOM。
- [x] JavaScript 通过语法检查；HTML 引用的本地 CSS、JS 文件均存在。
- [x] README 已注明原项目、实测环境、安装、使用、卸载、隐私与已知限制。
- [x] NOTICE 与 LICENSE 未把无标准许可证的上游代码误标为 MIT 或 GPL。

## 发布前仍需确认

- [x] 将无书名、无账户信息的 PW3 原生截图保存为 `docs/images/pw3-reading-time-overview.png`，并在 README 中加入图片。
- [x] 由 Echo 通读 README、NOTICE、LICENSE，确认署名和说明符合原作者授权原意。
- [ ] 在 GitHub 创建仓库后检查首页排版、内部链接与图片是否正常。
- [ ] 创建首个预览 Release，并明确标为 `v0.1.0-preview`。
- [ ] 若能找到第二台兼容设备，从零安装复测后再考虑标记稳定版。

## 每次打包都要检查

发布 ZIP 中不得出现以下设备生成文件：

- `reading-time.tsv`
- 生成后的真实 `data.js`
- `*.log`
- `state.txt`、`report.txt`
- `*.db`、`*.db-journal`
- `backups/`
- `wininfo_screenshot_*.txt`

安装 ZIP 应只包含 `package` 目录内的公开安装文件；仓库源码压缩包可额外包含 README、说明与截图。
