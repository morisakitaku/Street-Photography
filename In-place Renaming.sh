#!/bin/bash
# ==========================================
# Chronos Move v2 - 原地重命名引擎
# 修改版：不移動到桌面，直接在選中的原資料夾內重新命名照片與影片
# ==========================================

INPUT_PATH="$1"

if [ -z "$INPUT_PATH" ] || [ ! -d "$INPUT_PATH" ]; then
    echo "❌ 錯誤：請提供正確的資料夾路徑。"
    echo "💡 請把資料夾拖到此程式上執行。"
    exit 1
fi

EXIFTOOL=$(which exiftool)

if [ -z "$EXIFTOOL" ]; then
    echo "❌ 找不到 ExifTool"
    exit 1
fi

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
-iname "*.m4v" \
\) | wc -l | tr -d ' ')

total_files=$((total_photos + total_videos))

echo "✅ 找到照片：$total_photos"
echo "🎞️ 找到影片：$total_videos"

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
# 照片原地處理
# ==========================================

while IFS= read -r -d '' file; do
    ((current_count++))
    filename=$(basename "$file")
    dir_name=$(dirname "$file")

    draw_progress_bar "$current_count" "$total_files" "$filename"

    timestamp=$("$EXIFTOOL" \
    -d "%Y.%m.%d - %H.%M.%S" \
    -DateTimeOriginal \
    -S -s "$file")

    [ -z "$timestamp" ] && \
    timestamp=$(date -r "$(stat -f %m "$file")" +"%Y.%m.%d - %H.%M.%S")

    ext="${file##*.}"
    target_file="${dir_name}/${timestamp}.${ext}"

    counter=2
    while [ -f "$target_file" ] && [ "$file" != "$target_file" ]; do
        target_file="${dir_name}/${timestamp}_${counter}.${ext}"
        ((counter++))
        ((rename_count++))
    done

    if [ "$file" != "$target_file" ]; then
        mv "$file" "$target_file"
    fi

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
# 影片原地處理
# ==========================================

while IFS= read -r -d '' file; do
    ((current_count++))
    filename=$(basename "$file")
    dir_name=$(dirname "$file")

    draw_progress_bar "$current_count" "$total_files" "$filename"

    timestamp=$("$EXIFTOOL" \
    -d "%Y.%m.%d - %H.%M.%S" \
    -api QuickTimeUTC \
    -DateTimeOriginal \
    -S -s "$file")

    [ -z "$timestamp" ] && \
    timestamp=$(date -r "$(stat -f %m "$file")" +"%Y.%m.%d - %H.%M.%S")

    ext="${file##*.}"
    target_file="${dir_name}/${timestamp}.${ext}"

    counter=2
    while [ -f "$target_file" ] && [ "$file" != "$target_file" ]; do
        target_file="${dir_name}/${timestamp}_${counter}.${ext}"
        ((counter++))
    done

    if [ "$file" != "$target_file" ]; then
        mv "$file" "$target_file"
    fi

done < <(find "$INPUT_PATH" -type f \( \
-iname "*.mov" -o \
-iname "*.mp4" -o \
-iname "*.m4v" \
\) -print0)

echo ""
echo "=========================================="
echo "🎉 原地重新命名完成"
echo "📂 目標資料夾：$INPUT_PATH"
echo "🔁 同秒檔案自動重新命名：${rename_count} 次"
echo "=========================================="

osascript -e 'display notification "資料夾內的照片與影片已原地重新命名完成！" with title "Chronos In-Place"'
