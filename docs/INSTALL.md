# 第一次安装 v0.1.1-preview

本页适用于此前没有安装过本插件的设备。开始前请先阅读仓库首页的兼容环境和风险说明。

## 安装前确认

1. Kindle 已完成与设备、固件相适配的越狱。
2. 已安装与设备兼容、包含 SH_Integration 的 Universal Hotfix。
3. Kindle 书库能够显示并运行 `documents` 文件夹中的 `.sh` Scriptlet。
4. 已备份 Kindle 中的重要书籍、阅读记录和现有插件。

> 能够在搜索栏执行 `;log runme`，不能单独证明 SH_Integration 已安装。如果复制 `.sh` 文件后书库始终不显示入口，应先检查 Universal Hotfix / SH_Integration，而不是反复重装本插件。

## 复制安装文件

1. 从 [Releases](https://github.com/GlanKaka/kindle-reading-time-pw3/releases) 下载并解压 `kindle-reading-time-pw3-v0.1.1-preview.zip`。
2. 用 USB 将 Kindle 连接到电脑。
3. 打开 Kindle 盘符的最外层。例如电脑显示 Kindle 为 `E:` 盘，就进入 `E:\`。
4. 将解压后看到的以下四项直接复制到 Kindle 盘符最外层：

   - `RUNME.sh`
   - `UNINSTALL-RUNME.sh`
   - `documents`
   - `pw3-reading-time`

不要把这四项整体放进另一个新文件夹，也不要只把它们放进 `documents`。

## 执行安装

1. 在电脑上安全弹出 Kindle，然后拔掉 USB。
2. 在 Kindle 首页搜索栏输入 `;log runme`。开头是英文分号，`log` 和 `runme` 中间有一个空格。
3. 等待约 10 秒。本适配版通常不会显示“安装完成”提示。
4. 返回 Kindle 书库，等待书库刷新，找到“PW3阅读时间.sh”并打开。

## 安装后使用

安装后后台服务会自动运行，不需要每次手动启动。正常使用 Kindle 原生阅读器看书即可；想查看记录时，在书库中打开“PW3阅读时间.sh”。首次打开、刚重启或刚拔掉 USB 时，页面可能启动稍慢，可稍等后再试一次。

## 常见问题

- **书库没有“PW3阅读时间.sh”**：优先检查 Universal Hotfix / SH_Integration 是否正确安装，并确认书库筛选条件没有隐藏文档。
- **安装后没有任何提示**：这是正常情况，等待约 10 秒后直接回书库查找入口。
- **暂时没有阅读数据**：先使用 Kindle 原生阅读器阅读一会儿，再打开记录页面。
- **需要反馈问题**：请提供 Kindle 型号、固件版本、越狱方式和现象；不要公开发送账号、序列号、`reading-time.tsv`、生成后的 `data.js` 或数据库文件。

