#!/bin/bash

# Script để publish library lên Maven
# Sử dụng: ./publish.sh --local hoặc ./publish.sh --remote

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Kiểm tra tham số đầu vào
if [ $# -eq 0 ]; then
    print_error "Vui lòng chỉ định target publish: --local hoặc --remote"
    echo "Sử dụng: ./publish.sh --local hoặc ./publish.sh --remote"
    exit 1
fi

PUBLISH_TARGET=$1

# Xác định task publish dựa trên tham số
case $PUBLISH_TARGET in
    --local)
        PUBLISH_TASK="publishToMavenLocal"
        print_info "Publish target: Maven Local"
        ;;
    --remote)
        PUBLISH_TASK="publish"
        print_info "Publish target: Maven Remote"
        
        # Kiểm tra các biến môi trường cần thiết cho remote publish
        if [ -z "$MAVEN_USERNAME" ] || [ -z "$MAVEN_PASSWORD" ]; then
            print_warning "Biến môi trường MAVEN_USERNAME và MAVEN_PASSWORD chưa được thiết lập"
            print_warning "Đảm bảo các thông tin xác thực đã được cấu hình trong gradle.properties hoặc environment variables"
        fi
        ;;
    *)
        print_error "Tham số không hợp lệ: $PUBLISH_TARGET"
        echo "Sử dụng: ./publish.sh --local hoặc ./publish.sh --remote"
        exit 1
        ;;
esac

echo ""
print_info "========================================="
print_info "Bắt đầu quá trình publish"
print_info "========================================="
echo ""

# Bước 1: Refresh dependencies
print_info "Bước 1: Refresh dependencies..."
./gradlew --refresh-dependencies || {
    print_error "Refresh dependencies thất bại!"
    exit 1
}
echo ""

# Bước 2: CocoaPods setup
print_info "Bước 2: Setup CocoaPods..."
if command -v pod &> /dev/null; then
    print_info "CocoaPods đã được cài đặt"
    
    # Chạy Gradle podInstall task
    print_info "Chạy podInstall task..."
    ./gradlew podInstall || {
        print_warning "podInstall task failed, tiếp tục..."
    }
else
    print_warning "CocoaPods chưa được cài đặt"
    print_info "Để cài đặt CocoaPods: sudo gem install cocoapods"
fi
echo ""

# Bước 3: Clean build
print_info "Bước 3: Clean build..."
./gradlew clean || {
    print_error "Clean thất bại!"
    exit 1
}
echo ""

# Bước 4: Build project  
print_info "Bước 4: Build project..."
# Generate cinterop bindings cho AFNetworking trên tất cả iOS platforms
print_info "Generating AFNetworking cinterop bindings..."
./gradlew :library:cinteropAFNetworkingIosArm64 :library:cinteropAFNetworkingIosX64 :library:cinteropAFNetworkingIosSimulatorArm64 || {
    print_error "CInterop generation thất bại!"
    exit 1
}

# Build và skip commonizeCInterop + compileIosMainKotlinMetadata
# (metadata compilation không cần thiết cho publish và gây lỗi với CocoaPods)
print_info "Building với skip metadata compilation..."
./gradlew build -x commonizeCInterop -x compileIosMainKotlinMetadata || {
    print_error "Build thất bại!"
    exit 1
}
echo ""

# Bước 5: Publish
print_info "Bước 5: Publish library..."
./gradlew $PUBLISH_TASK -x commonizeCInterop -x compileIosMainKotlinMetadata || {
    print_error "Publish thất bại!"
    exit 1
}
echo ""

# Thành công
print_info "========================================="
print_info "✓ Publish thành công!"
if [ "$PUBLISH_TARGET" == "--local" ]; then
    print_info "Library đã được publish vào Maven Local (~/.m2/repository)"
else
    print_info "Library đã được publish lên Maven Remote"
fi
print_info "========================================="
