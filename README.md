### netease-lrc-downloader
根据163key为网易云的音乐文件提取ID和下载歌词的脚本
[!预览图](https://github.com/Webpage-gh/netease-lrc-downloader/raw/refs/heads/main/preview.png)
用法：安装`exiftool` `openssl` `jq`，下载`music.sh`，cd后执行
bash music.sh [命令] [-q] [-f] (ID|文件路径)

命令：
空 从文件解析ID并下载歌词到歌曲所在文件夹，
参数：[-q] [-f]。-q和-f位置可以互换，指定-q时安静输出，指定-f时强制覆盖
getid 只解析ID，参数为文件路径
down 根据ID下载歌词到标准输出，参数为ID

例子：
```
bash music.sh getid /sdcard/Music/neteasemusic.mp3
```
```
bash music.sh -q -f neteasemusic.flac
```

errcode 1为参数无效，2为命令检查失败，3为输入检查失败，4为目标文件无法覆盖
