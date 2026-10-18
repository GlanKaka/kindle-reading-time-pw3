# 升级到 v0.1.1-preview

本页适用于已经安装 `v0.1.0-preview`，希望升级并保留原有阅读记录的设备。

## 升级前备份

1. 用 USB 将 Kindle 连接到电脑。
2. 找到 Kindle 根目录下的 `pw3-reading-time` 文件夹。
3. 将 `pw3-reading-time/reading-time.tsv` 单独复制到电脑安全位置备份。

> 不要先运行卸载脚本，也不要删除整个 `pw3-reading-time` 文件夹，否则可能一并删除尚未备份的阅读记录。

## 覆盖程序文件

1. 从 [Releases](https://github.com/GlanKaka/kindle-reading-time-pw3/releases) 下载并解压 `kindle-reading-time-pw3-v0.1.1-preview.zip`。
2. 将解压后看到的以下四项复制到 Kindle USB 盘符最外层：

   - `RUNME.sh`
   - `UNINSTALL-RUNME.sh`
   - `documents`
   - `pw3-reading-time`

3. Windows 询问时，选择合并文件夹并覆盖同名文件。

新版安装包不含 `reading-time.tsv`，不会通过这次复制覆盖已有阅读记录。

## 执行升级

1. 在电脑上安全弹出 Kindle，然后拔掉 USB。
2. 在 Kindle 首页搜索栏输入 `;log runme`。
3. 等待约 10 秒。本适配版通常不会显示“安装完成”提示。
4. 在书库打开“PW3阅读时间.sh”。

## 升级后确认

1. 原来的累计时长和每日记录仍然存在。
2. 能按书籍 ID 与 Kindle 本地书库匹配的中文书籍，优先显示书库中的正式中文标题。
3. 匹配不到的书籍仍会显示原内部名称，这不代表阅读数据丢失。

如果页面看起来仍是旧版，可关闭页面后重新打开一次；`v0.1.1-preview` 已增加脚本版本参数，以降低 WebView 使用旧缓存的概率。


