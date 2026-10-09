cmake_minimum_required(VERSION 3.22.1)
project("lanplayer_native" LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# ===== libass JNI 桥接 =====
#
# libass 依赖链: libass -> freetype + fribidi + harfbuzz
# 编译方式: 使用 build_native_deps.sh 交叉编译所有依赖
# 编译产物放在 android/app/src/main/cpp/libs/<ABI>/
#
# 如果 libs 目录不存在（首次构建或未运行编译脚本），
# 则跳过 libass 编译，仅提供 JNI 桩代码。

set(NATIVE_LIBS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}")

# JNI 桥接库（始终编译）
add_library(lanplayer_jni SHARED
    lanplayer_jni.cpp
    lanplayer_mpv.cpp
    iso_native.cpp
    # libudfread:蓝光 ISO 的 UDF 文件系统解析(纯 C,零依赖,源码直编)
    libudfread/udfread.c
    libudfread/udf_volume.c
    libudfread/udf_fs.c
    libudfread/ecma167.c
    libudfread/udfread-version.c
)

target_include_directories(lanplayer_jni PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/libudfread"
)

target_compile_definitions(lanplayer_jni PRIVATE HAS_LIBUDFREAD=1)

# 查找 Android 日志库
find_library(log-lib log)
target_link_libraries(lanplayer_jni ${log-lib})

# ===== libass 集成 =====
if(EXISTS "${NATIVE_LIBS_DIR}/libass.a")
    message(STATUS "Found libass (static) for ${ANDROID_ABI}, enabling ASS subtitle rendering")

    # 预编译的静态库
    add_library(ass STATIC IMPORTED)
    set_target_properties(ass PROPERTIES
        IMPORTED_LOCATION "${NATIVE_LIBS_DIR}/libass.a")

    add_library(freetype STATIC IMPORTED)
    set_target_properties(freetype PROPERTIES
        IMPORTED_LOCATION "${NATIVE_LIBS_DIR}/libfreetype.a")

    add_library(fribidi STATIC IMPORTED)
    set_target_properties(fribidi PROPERTIES
        IMPORTED_LOCATION "${NATIVE_LIBS_DIR}/libfribidi.a")

    add_library(harfbuzz STATIC IMPORTED)
    set_target_properties(harfbuzz PROPERTIES
        IMPORTED_LOCATION "${NATIVE_LIBS_DIR}/libharfbuzz.a")

    # 头文件路径
    target_include_directories(lanplayer_jni PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${NATIVE_LIBS_DIR}/include"
    )

    # 链接
    target_link_libraries(lanplayer_jni
        ass freetype fribidi harfbuzz
        ${log-lib}
    )

    target_compile_definitions(lanplayer_jni PRIVATE HAS_LIBASS=1)

elseif(EXISTS "${NATIVE_LIBS_DIR}/libass.so")
    message(STATUS "Found libass (dynamic) for ${ANDROID_ABI}, enabling ASS subtitle rendering")

    # 预编译的动态库（如 ChaiChaiEmbyTV 提取的 libass.so，内含 freetype/fribidi/harfbuzz）
    add_library(ass SHARED IMPORTED)
    set_target_properties(ass PROPERTIES
        IMPORTED_LOCATION "${NATIVE_LIBS_DIR}/libass.so")

    # 头文件路径
    target_include_directories(lanplayer_jni PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
    )

    # 链接动态库
    target_link_libraries(lanplayer_jni
        ass
        ${log-lib}
    )

    target_compile_definitions(lanplayer_jni PRIVATE HAS_LIBASS=1)

else()
    message(STATUS "libass not found for ${ANDROID_ABI}, building stub only")
    target_compile_definitions(lanplayer_jni PRIVATE HAS_LIBASS=0)
endif()

# ===== 定制 libmpv 集成（NativeSurfaceEngine 视频内核）=====
# libmp2.so: mpv-android 构建链产物，静态编入 libass+fontconfig+
# ffmpeg(MediaCodec 硬解)+lua+libplacebo+curl。arm64-v8a 先行。
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libmp2.so")
    message(STATUS "Found custom libmpv(libmp2) for ${ANDROID_ABI}, enabling HAS_MPV")
    add_library(mpv_custom SHARED IMPORTED)
    set_target_properties(mpv_custom PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libmp2.so")
    target_include_directories(lanplayer_jni PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/mpv_include")
    find_library(android-lib android)
    target_link_libraries(lanplayer_jni mpv_custom ${android-lib})
    target_compile_definitions(lanplayer_jni PRIVATE HAS_MPV=1)
else()
    message(STATUS "custom libmpv not found for ${ANDROID_ABI}, JNI stubs only")
endif()
