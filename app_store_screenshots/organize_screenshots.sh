#!/bin/bash
echo "📁 Moving screenshots from Desktop to organized folders..."

# Find all iOS Simulator screenshots on Desktop
for file in ~/Desktop/Simulator*.png; do
    if [ -f "$file" ]; then
        echo "Found screenshot: $(basename "$file")"
        echo "Which device is this from?"
        echo "1) iPhone 15 Pro Max"
        echo "2) iPhone 14 Plus" 
        echo "3) iPhone 8 Plus"
        echo "4) Skip this file"
        read -p "Enter choice (1-4): " choice
        
        case $choice in
            1) mv "$file" "iPhone_15_Pro_Max/" ;;
            2) mv "$file" "iPhone_14_Plus/" ;;
            3) mv "$file" "iPhone_8_Plus/" ;;
            4) echo "Skipping..." ;;
            *) echo "Invalid choice, skipping..." ;;
        esac
    fi
done
echo "✅ Done organizing screenshots!"
