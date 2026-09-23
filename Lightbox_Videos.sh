#!/bin/bash
# ==========================================
# Lightbox Videos - 影片安全壓縮與同步引擎 (Street Photography 版)
# ==========================================

PARENT_DIR="$HOME/Desktop/Street Photography"
SOURCE_DIR="${PARENT_DIR}/Source"
SCREENERS_ROOT="${PARENT_DIR}/Screeners"

mkdir -p "$SOURCE_DIR" "$SCREENERS_ROOT"

FFMPEG=$(which ffmpeg || echo "/opt/homebrew/bin/ffmpeg")

echo "🔍 開始掃描並壓縮影片（保留高品質與 Metadata）..."

# 【防無限遞迴鎖】過濾掉已經是 _scr 的影片
find "$SOURCE_DIR" -type f \( -iname "*.mov" -o -iname "*.mp4" -o -iname "*.m4v" \) ! -name "*_scr.*" -print0 | while IFS= read -r -d '' file; do
    
    filename=$(basename "$file")
    file_dir=$(dirname "$file")
    base="${filename%.*}"
    
    out_scr="$SCREENERS_ROOT/${base}_scr.mp4"
    sidecar_in_source="$file_dir/${base}_scr.mp4"
    
    if [ -f "$out_scr" ]; then
        continue
    fi
    
    echo "==================================="
    echo "🎬 正在壓縮: $filename"
    
    # 高畫質核心壓縮指令 (1080p, crf 20, 8Mbps)
    "$FFMPEG" -nostdin -i "$file" -map_metadata 0 -metadata:s:v:0 rotate=0 -vf "scale=1920:-2" -c:v libx264 -preset medium -crf 20 -maxrate 8M -bufsize 16M -c:a aac -b:a 192k -y "$out_scr"
    
    if [ $? -eq 0 ]; then
        echo "✅ 壓縮成功: $(basename "$out_scr")"
        if [ ! -f "$sidecar_in_source" ]; then
            cp -p "$out_scr" "$sidecar_in_source"
            echo "✅ 同步縮影至 Source: $(basename "$sidecar_in_source")"
        fi
    else
        echo "❌ 壓縮失敗: $filename"
    fi
done

echo "==================================="
echo "🎉 Lightbox 影片壓縮與同步全部完成！"
echo "📂 主資料夾：$PARENT_DIR"