#!/bin/bash
# ==========================================
# Negatives 預覽圖完整性查漏工具 (Street Photography 版)
# ==========================================

PARENT_DIR="$HOME/Desktop/Street Photography"
NEGATIVES_DIR="${PARENT_DIR}/Negatives"
LOG_FILE="${PARENT_DIR}/Missing_Previews.txt"

> "$LOG_FILE" # 清空舊紀錄

echo "🔍 正在掃描 Street Photography/Negatives 資料夾檔案中..."
echo "這可能需要十幾秒鐘，請稍候..."

# ==========================
# 統計照片數量
# ==========================

TOTAL_FILES=$(find "$NEGATIVES_DIR" -type f \( -iname "*.raf" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -name "*_cs.*" | wc -l | tr -d ' ')

UNIQUE_BASES=$(find "$NEGATIVES_DIR" -type f \( -iname "*.raf" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -name "*_cs.*" | sed 's/\.[^.]*$//' | sort -u | wc -l | tr -d ' ')

DUPLICATE_PAIRS=$((TOTAL_FILES - UNIQUE_BASES))

# ==========================
# 檢查是否缺少 _cs.jpg
# ==========================

find "$NEGATIVES_DIR" -type f \( -iname "*.raf" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -name "*_cs.*" -print0 | while IFS= read -r -d '' file; do
    echo "${file%.*}"
done | sort -u | while IFS= read -r unique_base; do

    # 檢查該基底名稱加上 _cs.jpg 是否存在
    if [ ! -f "${unique_base}_cs.jpg" ]; then
        echo "${unique_base}_cs.jpg" >> "$LOG_FILE"
    fi

done

MISSING_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')

echo "=================================================="
echo "📸 原始照片檔案數：$TOTAL_FILES"
echo "📂 去除副檔名後的照片組數：$UNIQUE_BASES"
echo "🔁 RAF+JPG（或其他同名不同副檔名）重複組數：$DUPLICATE_PAIRS"
echo "=================================================="

if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "✅ 太棒了！掃描完畢，所有照片（包含 RAF+JPG 組合）都擁有對應的 _cs.jpg 預覽圖！"
    echo "你的捷徑完美完成了任務，沒有任何遺漏。"
    rm -f "$LOG_FILE"
else
    echo "⚠️ 掃描完畢！發現有 $MISSING_COUNT 組照片缺少預覽圖。"
    echo "📄 詳細的缺失清單已儲存至：$LOG_FILE"
fi

echo "=================================================="