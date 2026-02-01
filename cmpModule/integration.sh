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

Integration guide for **$artifact** library into Consumer App (Kotlin Multiplatform).

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

Add Maven repository to \`settings.gradle.kts\`:

\`\`\`kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        mavenLocal() // ✅ For local development
        // maven("https://your-maven-repo.com/releases") // ✅ Or your Maven remote repository
    }
}
\`\`\`

### Step 2: Add Dependency

In your shared module's \`build.gradle.kts\`:

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

This library requires the following iOS frameworks in your iOS project:

$ios_frameworks_list

**You can integrate these frameworks using one of the following methods:**
- **CocoaPods**: Add corresponding pods to Podfile
- **Swift Package Manager**: Add corresponding package dependencies
- **Manual**: Download and link frameworks manually

**Important**: Ensure all frameworks above are properly integrated into your iOS project, otherwise the app will crash at runtime with "framework not found" or "undefined symbol" errors.

### Step 4: Sync Project

\`\`\`bash
# Refresh dependencies
./gradlew --refresh-dependencies

# Build project
./gradlew build
\`\`\`

## 🔧 Platform-Specific Implementation

### iOS
- Library uses native iOS frameworks listed in Step 3
- Supports iOS 13.0+
- Ensure all framework dependencies are properly linked

## 🐛 Troubleshooting

### iOS: "framework not found" or "Undefined symbol"

**Cause**: Missing iOS framework dependencies.

**Solution:**
1. Check Step 3 - ensure all required frameworks are integrated
2. If using CocoaPods:
   - Run \`pod install\`
   - Open \`*.xcworkspace\` (NOT .xcodeproj)
   - Clean build: Product → Clean Build Folder
3. If using SPM:
   - File → Add Package Dependencies
   - Add corresponding packages
   - Rebuild project
4. Restart Xcode and rebuild

### Android: "Unable to resolve host"

**Solution:**
1. Check INTERNET permission in AndroidManifest.xml
2. Restart emulator with Cold Boot
3. Verify emulator has internet connection
4. Test on real device

### Build Error: "commonizeCInterop failed"

**Solution:**
- Already handled in library with \`kotlin.mpp.enableCInteropCommonization=false\`
- If still encountering errors, try cleaning cache:
  \`\`\`bash
  ./gradlew clean
  ./gradlew --stop
  rm -rf .gradle build
  \`\`\`

## 🔄 Updating Library

\`\`\`bash
# Update version in build.gradle.kts
implementation("$group:$artifact:NEW_VERSION")

# Sync dependencies
./gradlew --refresh-dependencies
\`\`\`

## 📝 Notes

- Library uses coroutines, ensure calling from coroutine scope
- All network operations are suspend functions
- iOS requires native frameworks integration (see Step 3)

## 💡 Best Practices

1. **Error Handling**: Always wrap network calls in try-catch
2. **Timeouts**: Default timeout is 30 seconds
3. **Threading**: Network calls automatically run on IO dispatcher
4. **Memory**: Networking instances are lightweight, can be created multiple times

## 🆘 Support

If you encounter issues, check:
1. [Troubleshooting section](#-troubleshooting)
2. Build logs in Gradle/Xcode
3. Verify iOS framework dependencies are fully integrated

---

**Generated by integration.sh** - $(date)
EOF

    print_info "✓ INTEGRATION.md generated successfully!"
    echo ""
    print_info "Preview:"
    head -20 INTEGRATION.md
    echo ""
    print_info "View full: cat INTEGRATION.md"
}

# Main
print_header "Library Integration Documentation Generator"
generate_integration_doc
