#!/bin/bash

print_help() {
  cat << EOF
从文件提取网易云音乐ID和下载歌词的小工具。
用法：$0 [命令] [-q] [-f] (ID|文件路径)

命令：
空 从文件解析ID并下载歌词到歌曲所在文件夹，
参数：[-q] [-f]。-q和-f位置可以互换，指定-q时安静输出，指定-f时强制覆盖
getid 只解析ID，参数为文件路径
down 根据ID下载歌词到标准输出，参数为ID

例子：
$0 getid /sdcard/Music/neteasemusic.mp3
$0 -q -f neteasemusic.flac

errcode 1为参数无效，2为命令检查失败，3为输入检查失败，4为目标文件无法覆盖
EOF
}

cmd_check() {
  # 命令检查
  for i in exiftool openssl jq; do
    if ! command -v "$i" > /dev/null; then
      "$i" # 有些终端会提示下载哪个软件包
      need_to_install=1
    fi
  done

  # 若存在一次失败，则退出
  if (( need_to_install )); then
    echo 请先安装以上命令，然后再运行此脚本 >&2
    return 2
  fi
}

file_check() {
  if [ -f "$1" ]; then
    if [ -r "$1" ]; then
      return
    else
      echo 文件 "$1" 存在但不可读，请检查权限 >&2
    fi
  else
    echo 文件 "$1" 不存在，请检查路径 >&2
  fi
  return 3
}

id_check() {
  if ! echo "$1" | grep -qE '^[0-9]{1,20}$'; then
    echo ID检查未通过 >&2
    return 3
  fi
}

out_check() {
  if (( ! is_force_cover )) && [[ -e "$1" ]]; then # 询问
    (( in_quiet )) && return 4
    printf "文件 %s 已存在，是否覆盖？[y/N]" "$1" >&2

    read -r -n 1 choice
    case "$choice" in
      y|Y|yes) echo;;
      *) return 4;;
    esac
  fi
}

smart_print() { (( in_quiet )) || echo "$1"; }

download() {
  lrc=$(curl -s --get "https://music.163.com/api/song/lyric" \
     --data-urlencode "id=$1" \
     --data-urlencode "lv=1" \
     --data-urlencode "tv=-1" |
    jq -r '.lrc?.lyric // empty')

  if [[ "$lrc" == empty ]]; then
    return 1
  else
    echo "$lrc"
  fi
}

get_id() {

  exiftool -s3 -Description "$1" |
  cut -d: -f2 |
  openssl enc -aes-128-ecb -d -a -K \
    "$(printf '#14ljk_!\]&0U<'\'\( | xxd -p)" |
  sed 's/^music://' |
  jq .musicId
}

cmd_check || exit 3 # 依赖项检查

# 解析参数
while getopts ":qf" opt; do
  case $opt in
    q) in_quiet=1;;
    f) is_force_cover=1;;
    *) echo "无效的选项：$opt"; exit 1;;
  esac
done
shift $((OPTIND - 1))

# 为了简化输入，这里的子命令与函数名称并不严格对应
case "$1" in
  ''|-h|--help) print_help;; 
  getid) file_check "$2" && get_id "$2";;
  down) id_check "$2" && download "$2";;
  *)
    file_check "$1" || exit $?
    # 获取ID后下载
    id=$(get_id "$1")
    id_check "$id" || exit $?
    smart_print "歌曲ID为 $id ，正在下载歌词"
    lrc_path=${1%%.*}.lrc # 把后缀换成lrc 
    out_check "$lrc_path" || exit $?
    download "$id" > "$lrc_path"
    smart_print "歌词文件已保存到 $lrc_path"
    ;;
esac
