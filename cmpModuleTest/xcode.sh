#!/bin/bash

# Script để quản lý các tác vụ liên quan đến Xcode project
# Sử dụng: ./xcode.sh <action> [options]

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hàm hiển thị thông báo
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}===========================================\n$1\n===========================================${NC}"
}

# Hàm tìm file Package.resolved
find_package_resolved() {
    local search_path="${1:-.}"
    find "$search_path" -name "Package.resolved" -type f 2>/dev/null
}

# Action: List Swift Package Manager packages
action_spm_list() {
    print_header "Swift Package Manager - Package List"
    
    # Tìm tất cả file Package.resolved từ thư mục gốc
    print_info "Tìm kiếm file Package.resolved..."
    local package_files=($(find_package_resolved .))
    
    if [ ${#package_files[@]} -eq 0 ]; then
        print_warning "Không tìm thấy file Package.resolved nào"
        exit 0
    fi
    
    print_info "Tìm thấy ${#package_files[@]} file Package.resolved\n"
    
    # Duyệt qua từng file và list packages
    for package_file in "${package_files[@]}"; do
        echo -e "${BLUE}📦 File: ${NC}$package_file"
        echo ""
        
        # Kiểm tra file có tồn tại và đọc được
        if [ ! -r "$package_file" ]; then
            print_error "Không thể đọc file: $package_file"
            continue
        fi
        
        # Parse JSON và list packages với version
        # Sử dụng python để parse JSON nếu có
        if command -v python3 &> /dev/null; then
            python3 << EOF
import json
import sys

try:
    with open('$package_file', 'r') as f:
        data = json.load(f)
    
    pins = data.get('pins', [])
    
    if not pins:
        print("  Không có package nào")
    else:
        print(f"  Tổng số packages: {len(pins)}\n")
        for pin in pins:
            identity = pin.get('identity', 'N/A')
            location = pin.get('location', 'N/A')
            state = pin.get('state', {})
            version = state.get('version', state.get('revision', 'N/A')[:8] if state.get('revision') else 'N/A')
            
            print(f"  📌 {identity}")
            print(f"     Version: {version}")
            print(f"     Location: {location}")
            print()
            
except Exception as e:
    print(f"  ❌ Lỗi parse JSON: {e}", file=sys.stderr)
    sys.exit(1)
EOF
        # Nếu không có python3, fallback sang grep/awk
        elif command -v jq &> /dev/null; then
            # Sử dụng jq nếu có
            jq -r '.pins[] | "  📌 \(.identity)\n     Version: \(.state.version // (.state.revision[:8] // "N/A"))\n     Location: \(.location)\n"' "$package_file"
        else
            # Fallback: parse thủ công đơn giản
            print_warning "Không tìm thấy python3 hoặc jq, hiển thị raw content"
            echo "  $(cat "$package_file")"
        fi
        
        echo ""
        echo "-------------------------------------------"
        echo ""
    done
}

# Hàm hiển thị usage
show_usage() {
    cat << EOF
Usage: ./xcode.sh <action> [options]

Actions:
  --spm-list              List tất cả Swift Package Manager packages và versions
                          từ file Package.resolved

Options:
  -h, --help             Hiển thị help message

Examples:
  ./xcode.sh --spm-list
  
EOF
}

# Main script
case "${1:-}" in
    --spm-list)
        action_spm_list
        ;;
    -h|--help|"")
        show_usage
        ;;
    *)
        print_error "Action không hợp lệ: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
