#!/bin/bash

# Script để generate tài liệu INTEGRATION.md
# Sử dụng: ./integration.sh

set -e

# Màu sắc cho output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}===========================================\n$1\n===========================================${NC}"
}

# Đọc thông tin từ build.gradle.kts
extract_build_info() {
    local build_file="library/build.gradle.kts"
    
    if [ ! -f "$build_file" ]; then
        echo "ERROR: Không tìm thấy $build_file"
        exit 1
    fi
    
    # Extract group, version, artifactId
    GROUP=$(grep '^group = ' "$build_file" | sed 's/group = "\(.*\)"/\1/')
    VERSION=$(grep '^version = ' "$build_file" | sed 's/version = "\(.*\)"/\1/')
    ARTIFACT_ID=$(grep 'val myArtifactId = ' "$build_file" | sed 's/.*= "\(.*\)"/\1/')
    
    echo "$GROUP:$ARTIFACT_ID:$VERSION"
}

# Extract CocoaPods dependencies từ build.gradle.kts
extract_cocoapods_deps() {
    local build_file="library/build.gradle.kts"
    
    # Extract pod dependencies - simple approach
    grep 'pod("' "$build_file" | sed 's/.*pod("\([^"]*\)").*/\1/' | while read pod_name; do
        # Try to find version for this pod
        local version=$(grep -A 2 "pod(\"$pod_name\")" "$build_file" | grep 'version = ' | sed 's/.*version = "\([^"]*\)".*/\1/')
        if [ -z "$version" ]; then
            version="latest"
        fi
        echo "$pod_name:$version"
    done
}

# Generate INTEGRATION.md
generate_integration_doc() {
    print_header "Generating INTEGRATION.md"
    
    local coords=$(extract_build_info)
    local group=$(echo "$coords" | cut -d: -f1)
    local artifact=$(echo "$coords" | cut -d: -f2)
    local version=$(echo "$coords" | cut -d: -f3)
    
    print_info "Library coordinates: $group:$artifact:$version"
    
    # Extract CocoaPods dependencies
    local pods_deps=$(extract_cocoapods_deps)
    print_info "CocoaPods dependencies detected:"
    echo "$pods_deps" | while read line; do
        echo "  - $line"
    done
    
    # Build iOS frameworks list
    local ios_frameworks_list=""
    if [ -n "$pods_deps" ]; then
        ios_frameworks_list=$(echo "$pods_deps" | while read line; do
            local pod_name=$(echo "$line" | cut -d: -f1)
            local pod_ver=$(echo "$line" | cut -d: -f2)
            echo "- **$pod_name** (\`$pod_ver\`)"
        done)
    fi
    
    cat > INTEGRATION.md << EOF
# Library Integration Guide

Hướng dẫn tích hợp library **$artifact** vào Consumer App (Kotlin Multiplatform).

## 📦 Library Information

- **Group ID**: \`$group\`
- **Artifact ID**: \`$artifact\`
- **Version**: \`$version\`
- **Maven Coordinates**: \`$group:$artifact:$version\`

## 🚀 Prerequisites

- Kotlin Multiplatform Project (Android + iOS)
- Gradle 8.0+
- Xcode 15.0+ (for iOS)

## 📥 Installation

### Step 1: Add Maven Repository

Thêm Maven repository vào \`settings.gradle.kts\`:

\`\`\`kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        mavenLocal() // For local development
        // Hoặc Maven remote repository của bạn
        // maven("https://your-maven-repo.com/releases")
    }
}
\`\`\`

### Step 2: Add Dependency

Trong \`build.gradle.kts\` của shared module:

\`\`\`kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("$group:$artifact:$version")
        }
    }
}
\`\`\`

### Step 3: iOS Frameworks Integration

Library này yêu cầu các iOS frameworks sau đây trong iOS project của bạn:

$ios_frameworks_list

**Bạn có thể integrate các frameworks này bằng một trong các cách:**
- **CocoaPods**: Thêm các pod tương ứng vào Podfile
- **Swift Package Manager**: Thêm các package dependencies tương ứng
- **Manual**: Download và link frameworks thủ công

**Quan trọng**: Đảm bảo tất cả các frameworks trên được integrate đầy đủ vào iOS project, nếu không app sẽ bị crash khi runtime với lỗi "framework not found" hoặc "undefined symbol".

### Step 4: Sync Project

\`\`\`bash
# Refresh dependencies
./gradlew --refresh-dependencies

# Build project
./gradlew build
\`\`\`

##  Platform-Specific Implementation

### iOS
- Library sử dụng native iOS frameworks được liệt kê ở Step 3
- Hỗ trợ iOS 13.0+
- Cần đảm bảo tất cả frameworks dependencies được link đúng

## 🐛 Troubleshooting

### iOS: "framework not found" hoặc "Undefined symbol"

**Nguyên nhân**: Thiếu iOS frameworks dependencies.

**Solution:**
1. Kiểm tra lại Step 3 - đảm bảo đã integrate tất cả frameworks cần thiết
2. Nếu dùng CocoaPods:
   - Chạy \`pod install\`
   - Mở \`*.xcworkspace\` (KHÔNG phải .xcodeproj)
   - Clean build: Product → Clean Build Folder
3. Nếu dùng SPM:
   - File → Add Package Dependencies
   - Add các packages tương ứng
   - Rebuild project
4. Restart Xcode và rebuild

### Android: "Unable to resolve host"

**Solution:**
1. Check INTERNET permission trong AndroidManifest.xml
2. Restart emulator với Cold Boot
3. Verify emulator có internet connection
4. Test trên real device

### Build Error: "commonizeCInterop failed"

**Solution:**
- Đã được handle trong library với \`kotlin.mpp.enableCInteropCommonization=false\`
- Nếu vẫn gặp lỗi, thử clean cache:
  \`\`\`bash
  ./gradlew clean
  ./gradlew --stop
  rm -rf .gradle build
  \`\`\`

##  Updating Library

\`\`\`bash
# Update version trong build.gradle.kts
implementation("$group:$artifact:NEW_VERSION")

# Sync dependencies
./gradlew --refresh-dependencies
\`\`\`

## 📝 Notes

- Library sử dụng coroutines, đảm bảo gọi từ coroutine scope
- Tất cả network operations là suspend functions
- iOS requires native frameworks integration (xem Step 3)
- Android cần INTERNET permission

## 💡 Best Practices

1. **Error Handling**: Always wrap network calls trong try-catch
2. **Timeouts**: Default timeout là 30 seconds
3. **Threading**: Network calls tự động chạy trên IO dispatcher
4. **Memory**: Networking instances are lightweight, có thể create nhiều lần

## 🆘 Support

Nếu gặp vấn đề, check:
1. [Troubleshooting section](#-troubleshooting)
2. Build logs trong Gradle/Xcode
3. Verify iOS frameworks dependencies đã được integrate đầy đủ

---

**Generated by integration.sh** - $(date)
EOF

    print_info "✓ INTEGRATION.md đã được tạo thành công!"
    echo ""
    print_info "Preview:"
    head -20 INTEGRATION.md
    echo ""
    print_info "Xem toàn bộ: cat INTEGRATION.md"
}

# Main
print_header "Library Integration Documentation Generator"
generate_integration_doc
