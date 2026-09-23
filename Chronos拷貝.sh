#!/bin/bash
# ==========================================
# Chronos Move v2 - 終端機專業歸檔引擎
# 修正版：支援 Sony CCD .mpg 影片與自動清理 .thm 檔案
# ==========================================

INPUT_PATH="$1"

if [ -z "$INPUT_PATH" ] || [ ! -d "$INPUT_PATH" ]; then
    echo "❌ 錯誤：請提供正確的資料夾路徑。"
    echo "💡 請把資料夾拖到此程式上執行。"
    exit 1
fi

PARENT_DIR="$HOME/Desktop/Street Photography"

NEGATIVES_DIR="${PARENT_DIR}/Negatives"
SOURCE_DIR="${PARENT_DIR}/Source"

mkdir -p "$NEGATIVES_DIR" "$SOURCE_DIR"

EXIFTOOL=$(which exiftool)

if [ -z "$EXIFTOOL" ]; then
    echo "❌ 找不到 ExifTool"
    exit 1
fi

echo "🧹 正在清理 Sony 伴隨的 .thm 縮圖檔案..."
find "$INPUT_PATH" -type f -iname "*.thm" -delete

echo "🔍 正在掃描檔案..."

total_photos=$(find "$INPUT_PATH" -type f \( \
-iname "*.jpg" -o \
-iname "*.jpeg" -o \
-iname "*.raf" -o \
-iname "*.RAF" -o \
-iname "*.png" -o \
-iname "*.dng" -o \
-iname "*.arw" -o \
-iname "*.cr2" -o \
-iname "*.nef" \
\) | wc -l | tr -d ' ')

total_videos=$(find "$INPUT_PATH" -type f \( \
-iname "*.mov" -o \
-iname "*.mp4" -o \
-iname "*.mpg" -o \
-iname "*.m4v" \
\) | wc -l | tr -d ' ')

total_files=$((total_photos + total_videos))

echo "✅ 找到照片：$total_photos"
echo "🎞️ 找到影片：$total_videos"[cite: 1]

current_count=0
rename_count=0

draw_progress_bar() {
    local current=$1
    local total=$2
    local filename=$3

    local length=30
    local percent=$((current * 100 / total))
    local filled=$((percent * length / 100))
    local empty=$((length - filled))

    local bar=$(printf "%${filled}s" | tr ' ' '█')
    local empty_bar=$(printf "%${empty}s" | tr ' ' '░')

    printf "\r\033[K⏳ [%s%s] %3d%% (%d/%d) %s" \
    "$bar" "$empty_bar" "$percent" "$current" "$total" "${filename:0:25}"
}

# ==========================================
# 照片處理
# ==========================================

while IFS= read -r -d '' file; do
    ((current_count++))
    filename=$(basename "$file")
    draw_progress_bar "$current_count" "$total_files" "$filename"

    rel_path=$("$EXIFTOOL" \
    -d "%Y/%Y %m/%Y %m %d" \
    -DateTimeOriginal \
    -S -s "$file")

    [ -z "$rel_path" ] && rel_path="Unknown"

    DEST_DIR="${NEGATIVES_DIR}/${rel_path}"
    mkdir -p "$DEST_DIR"

    timestamp=$("$EXIFTOOL" \
    -d "%Y.%m.%d - %H.%M.%S" \
    -DateTimeOriginal \
    -S -s "$file")

    [ -z "$timestamp" ] && \
    timestamp=$(date -r "$(stat -f %m "$file")" +"%Y.%m.%d - %H.%M.%S")

    ext="${file##*.}"
    target_file="${DEST_DIR}/${timestamp}.${ext}"

    counter=2
    while [ -f "$target_file" ]; do
        target_file="${DEST_DIR}/${timestamp}_${counter}.${ext}"
        ((counter++))
        ((rename_count++))
    done

    mv "$file" "$target_file"

done < <(find "$INPUT_PATH" -type f \( \
-iname "*.jpg" -o \
-iname "*.jpeg" -o \
-iname "*.raf" -o \
-iname "*.RAF" -o \
-iname "*.png" -o \
-iname "*.dng" -o \
-iname "*.arw" -o \
-iname "*.cr2" -o \
-iname "*.nef" \
\) -print0)

# ==========================================
# 影片處理 (含 .mpg 支援)
# ==========================================

while IFS= read -r -d '' file; do
    ((current_count++))
    filename=$(basename "$file")
    draw_progress_bar "$current_count" "$total_files" "$filename"

    timestamp=$("$EXIFTOOL" \
    -d "%Y.%m.%d - %H.%M.%S" \
    -api QuickTimeUTC \
    -DateTimeOriginal \
    -S -s "$file")

    # 針對舊版 mpg 若讀不到 DateTimeOriginal，自動退回抓取檔案修改時間
    [ -z "$timestamp" ] && \
    timestamp=$(date -r "$(stat -f %m "$file")" +"%Y.%m.%d - %H.%M.%S")

    ext="${file##*.}"
    target_file="${SOURCE_DIR}/${timestamp}.${ext}"

    counter=2
    while [ -f "$target_file" ]; do
        target_file="${SOURCE_DIR}/${timestamp}_${counter}.${ext}"
        ((counter++))
    done

    mv "$file" "$target_file"

done < <(find "$INPUT_PATH" -type f \( \
-iname "*.mov" -o \
-iname "*.mp4" -o \
-iname "*.mpg" -o \
-iname "*.m4v" \
\) -print0)

echo ""
echo "=========================================="
echo "🎉 Chronos 歸檔完成"[cite: 1]
echo "📂 主資料夾：$PARENT_DIR"[cite: 1]
echo "📂 照片子目錄：$NEGATIVES_DIR"[cite: 1]
echo "🎞️ 影片子目錄：$SOURCE_DIR"[cite: 1]
echo "🔁 同秒照片自動重新命名：${rename_count} 次"[cite: 1]
echo "=========================================="

osascript -e 'display notification "照片與影片已安全歸檔至 Street Photography！" with title "Chronos Move v2"'[cite: 1]