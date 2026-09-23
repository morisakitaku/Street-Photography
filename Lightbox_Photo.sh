#!/bin/bash
# ==========================================
# Lightbox PHOTO - 極速預覽圖引擎 (終極秒殺版)
# ==========================================

# 1. 檢查是否輸入了目標資料夾
INPUT_PATH="$1"
if [ -z "$INPUT_PATH" ] || [ ! -d "$INPUT_PATH" ]; then
    echo "❌ 錯誤：請提供正確的資料夾路徑。"
    exit 1
fi

# 2. 設定儲存路徑
PARENT_DIR="$HOME/Desktop/Street Photography"
CONTACT_SHEET_ROOT="${PARENT_DIR}/Contact Sheet"
NEGATIVES_ROOT="${PARENT_DIR}/Negatives"

mkdir -p "$CONTACT_SHEET_ROOT" "$NEGATIVES_ROOT"

EXIFTOOL=$(which exiftool || echo "/opt/homebrew/bin/exiftool")
if [ ! -x "$EXIFTOOL" ]; then
    echo "❌ 錯誤：找不到 ExifTool！請確認是否已安裝。"
    exit 1
fi

echo "🔍 正在高速掃描檔案，請稍候..."

# 這裡依然會算出原檔的數量
total_photos=$(find "$INPUT_PATH" -type f \( -iname "*.raf" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -name "*_cs.*" | wc -l | tr -d ' ')

if [ "$total_photos" -eq 0 ]; then
    echo "✅ 掃描完畢！指定的資料夾中沒有原檔。"
    exit 0
fi

echo "✅ 總共找到 $total_photos 張來源照片"
echo "🚀 開始極速檢查與生成預覽圖..."
echo "--------------------------------------------------"

current_count=0

# ==========================================
# 定義進度條函數
# ==========================================
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
    
    printf "\r\033[K🖼️ 進度: [%s%s] %3d%% (%d/%d) | 正在處理: %s" "$bar" "$empty_bar" "$percent" "$current" "$total" "${filename:0:20}"
}

# ==========================================
# 核心處理區塊
# ==========================================
while IFS= read -r -d '' file; do
    
    filename=$(basename "$file")
    base_name="${filename%.*}"
    file_dir=$(dirname "$file")
    
    # 再次確認不要抓到預覽圖
    if [[ "$filename" =~ _cs\. ]]; then
        continue
    fi
    
    # 【終極優化：同目錄秒殺檢查】
    # 如果原檔正旁邊已經有 _cs.jpg，代表在 Negatives 裡已經處理過了
    # 直接無痕跳過，連 ExifTool 和進度條都不啟動！
    if [ -f "$file_dir/${base_name}_cs.jpg" ]; then
        continue
    fi
    
    # 只有真正需要處理的照片，才會增加計數並畫出進度條
    ((current_count++))
    draw_progress_bar "$current_count" "$total_photos" "$filename"
    
    # ExifTool 只叫醒 1 次獲取 YYYY MM DD
    raw_date=$("$EXIFTOOL" -d "%Y %m %d" -DateTimeOriginal -s3 "$file" 2>/dev/null)
    
    if [ -z "$raw_date" ]; then
        date_path_cs="Unknown"
        date_path_neg="Unknown"
    else
        yyyy="${raw_date:0:4}"
        mm="${raw_date:5:2}"
        dd="${raw_date:8:2}"
        date_path_cs="$yyyy $mm"
        date_path_neg="$yyyy/$yyyy $mm/$yyyy $mm $dd"
    fi
    
    target_folder_cs="$CONTACT_SHEET_ROOT/$date_path_cs"
    target_folder_neg="$NEGATIVES_ROOT/$date_path_neg"
    
    out_jpg="$target_folder_cs/${base_name}_cs.jpg"
    final_copy_neg="$target_folder_neg/${base_name}_cs.jpg"
    
    # 檢查 Contact Sheet 是否已有檔案 (應付剛從相機 SD 卡匯入的情況)
    if [ -f "$out_jpg" ]; then
        if [ ! -f "$final_copy_neg" ]; then
            mkdir -p "$target_folder_neg"
            cp -p "$out_jpg" "$final_copy_neg"
        fi
        continue
    fi

    # 確定要轉碼了，建立資料夾
    mkdir -p "$target_folder_cs" "$target_folder_neg"
    temp_preview="$target_folder_cs/temp_${base_name}.jpg"
    
    # 執行轉碼與壓縮
    if [[ "$filename" =~ \.[rR][aA][fF]$ ]]; then
        "$EXIFTOOL" -b -PreviewImage "$file" > "$temp_preview" 2>/dev/null
        if [ -s "$temp_preview" ]; then
            sips -s format jpeg -s formatOptions 70 -Z 2048 "$temp_preview" --out "$out_jpg" >/dev/null 2>&1
        fi
        rm -f "$temp_preview"
    else
        sips -s format jpeg -s formatOptions 70 -Z 2048 "$file" --out "$out_jpg" >/dev/null 2>&1
    fi
    
    # 成功產出後，補回拍攝參數並備份
    if [ -f "$out_jpg" ]; then
        "$EXIFTOOL" -TagsFromFile "$file" "-all:all" "$out_jpg" -overwrite_original >/dev/null 2>&1
        cp -p "$out_jpg" "$final_copy_neg"
    fi

done < <(find "$INPUT_PATH" -type f \( -iname "*.raf" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -name "*_cs.*" -print0)

# ==========================================
# 完成提示
# ==========================================
echo -e "\n\n🎉 任務圓滿完成！所有預覽圖已極速生成並安全歸檔。"
osascript -e 'display notification "照片預覽圖極速生成與同步已完成！" with title "Lightbox 處理引擎"'