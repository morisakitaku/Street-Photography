#!/bin/bash
# ==========================================
# Lightbox Videos - 影片安全壓縮與同步引擎 (Street Photography 版)
# 修正版：支援 Sony CCD .mpg 格式與相容低解析度轉碼
# ==========================================

PARENT_DIR="$HOME/Desktop/Street Photography"
SOURCE_DIR="${PARENT_DIR}/Source"
SCREENERS_ROOT="${PARENT_DIR}/Screeners"

mkdir -p "$SOURCE_DIR" "$SCREENERS_ROOT"

FFMPEG=$(which ffmpeg || echo "/opt/homebrew/bin/ffmpeg")

echo "🔍 開始掃描並壓縮影片（支援 .mpg 與舊格式轉換）..."

# 【防無限遞迴鎖】過濾掉已經是 _scr 的影片，並加入 .mpg 支援
find "$SOURCE_DIR" -type f \( -iname "*.mov" -o -iname "*.mp4" -o -iname "*.m4v" -o -iname "*.mpg" \) ! -name "*_scr.*" -print0 | while IFS= read -r -d '' file; do
    
    filename=$(basename "$file")
    file_dir=$(dirname "$file")
    base="${filename%.*}"
    
    out_scr="$SCREENERS_ROOT/${base}_scr.mp4"
    sidecar_in_source="$file_dir/${base}_scr.mp4"
    
    if [ -f "$out_scr" ]; then
        continue
    fi
    
    echo "==================================="
    echo "🎬 正在轉換與壓縮: $filename"
    
    # 針對舊 CCD 低解析度影片的安全轉碼指令（使用 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" 確保維持原解析度並符合 H.264 偶數像素要求）
    "$FFMPEG" -nostdin -i "$file" -map_metadata 0 -metadata:s:v:0 rotate=0 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 192k -y "$out_scr"
    
    if [ $? -eq 0 ]; then
        echo "✅ 轉換成功: $(basename "$out_scr")"
        if [ ! -f "$sidecar_in_source" ]; then
            cp -p "$out_scr" "$sidecar_in_source"
            echo "✅ 同步縮影至 Source: $(basename "$sidecar_in_source")"
        fi
    else
        echo "❌ 轉換失敗: $filename"
    fi
done

echo "==================================="
echo "🎉 Lightbox 影片轉換與壓縮全部完成！"
echo "📂 主資料夾：$PARENT_DIR"