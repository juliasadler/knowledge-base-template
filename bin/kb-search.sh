#!/usr/bin/env bash
# kb-search.sh —— 主题知识库通用关键词检索
#
# 输入：
#   $1  关键词（必填，支持 grep 正则）
#   $2  起始目录（可选，默认检索 知识库/ 索引与维护/ 备用库/）
#
# 输出：
#   按目录分组打印命中：【主库】知识库/、索引与维护/ 的命中在前，
#   【备选库·仅作参考】备用库/ 的命中在后。
#   每行格式：文件路径:行号:行内容
#
# 退出码：
#   0 = 有命中，1 = 无命中，2 = 用法错误
#
# 用法示例：
#   ./bin/kb-search.sh "关键词"
#   ./bin/kb-search.sh "关键词" 知识库/
#
# 约定：
#   - 检索前请先按《规则/检索规范.md》走三层检索顺序
#     （概念索引→主题索引→全文检索），本脚本是第三层的全文检索工具。
#   - 结果中的来源标注规则见《规则/主备库隔离规则.md》。

set -u

if [ $# -lt 1 ]; then
  echo "用法: $0 \"关键词\" [起始目录]" >&2
  exit 2
fi

KEYWORD="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT" || exit 2

found=0

search_dir() {
  # $1=组标签 $2=目录
  local label="$1" dir="$2"
  [ -d "$dir" ] || return 0
  local hits
  hits=$(grep -rn --include="*.md" --include="*.txt" "$KEYWORD" "$dir" 2>/dev/null | grep -v "/README.md:")
  if [ -n "$hits" ]; then
    echo "== $label · $dir/ =="
    echo "$hits"
    echo ""
    found=1
  fi
}

if [ $# -ge 2 ]; then
  # 指定了起始目录：只在该目录内检索，不做主备分组
  dir="$2"
  if [ -d "$dir" ]; then
    hits=$(grep -rn --include="*.md" --include="*.txt" "$KEYWORD" "$dir" 2>/dev/null | grep -v "/README.md:")
    if [ -n "$hits" ]; then
      echo "$hits"
      found=1
    fi
  else
    echo "目录不存在: $dir" >&2
    exit 2
  fi
else
  search_dir "【主库】" "知识库"
  search_dir "【主库】" "索引与维护"
  search_dir "【备选库·仅作参考】" "备用库"
fi

if [ "$found" -eq 0 ]; then
  echo "库内无命中：$KEYWORD"
  exit 1
fi
exit 0
