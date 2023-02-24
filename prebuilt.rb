#!/usr/bin/env ruby

require "fileutils"
require "open3"



def get_main_path
    File.dirname(File.realdirpath(caller[0].match(/^(.*?):/)[1]))
end

def get_canonicalized_root_src (fp)
    File.realpath(fp, $main_path)
end

def exec_and_print (cmd)
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets
            puts line
        end
    end
end

def build_glog (abi)
    build_dir = "./build_#{abi}"
    install_dir = "#{Dir.pwd}/glog/#{abi}"
    glog_src = get_canonicalized_root_src "glog"
    Dir.chdir(glog_src)
    if Dir.exist?(build_dir)
        puts ">>> Cleaning previous build intermediates"
        FileUtils.rm_r(build_dir)
    end
    puts ">>> Building glog for #{abi}"
    exec_and_print(""" \
        #{$cmake} -B#{build_dir} -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE=#{ENV["ANDROID_NDK_ROOT"]}/build/cmake/android.toolchain.cmake \
        -DCMAKE_MAKE_PROGRAM=#{$ninja} \
        -DANDROID_ABI=#{abi} \
        -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
        -DANDROID_STL=c++_shared \
        -DCMAKE_INSTALL_PREFIX=#{install_dir} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DWITH_GFLAGS=OFF \
        -DWITH_GTEST=OFF \
        -DWITH_UNWIND=OFF \
        -DBUILD_TESTING=OFF""")
    exec_and_print("#{$cmake} --build #{build_dir} --target install")
    
    FileUtils.rm_r("#{install_dir}/lib/pkgconfig")
end

if __FILE__ == $0

    if not ENV.include?("ANDROID_SDK_ROOT")
        raise ArgumentError, "ANDROID_SDK_ROOT should be set to Android SDK path."
    end
    
    if not ENV.include?("ANDROID_NDK_ROOT")
        raise ArgumentError, "ANDROID_NDK_ROOT should be set to Android NDK path."
    end
    
    if not ENV.include?("ANDROID_SDK_CMAKE_VERSION")
        raise ArgumentError, "ANDROID_SDK_CMAKE_VERSION should be set to desired cmake version in $ANDROID_SDK_ROOT/cmake. eg. 3.18.1"
    end
    
    if not ENV.include?("ANDROID_PLATFORM")
        raise ArgumentError, "ANDROID_PLATFORM should be set to minimum API level supported by the library. eg. 21"
    end
    
    if not ENV.include?("ANDROID_ABI")
        raise ArgumentError, "ANDROID_ABI not set; can be a ',' separated list. eg. armeabi-v7a,arm64-v8a"
    end
    
    android_sdk_cmake_bin = "#{ENV["ANDROID_SDK_ROOT"]}/cmake/#{ENV["ANDROID_SDK_CMAKE_VERSION"]}/bin"
    $cmake = "#{android_sdk_cmake_bin}/cmake"
    $ninja = "#{android_sdk_cmake_bin}/ninja"
    
    if not File::exist?($cmake)
        raise "Cannot find cmake: '#{$cmake}'"
    end

    $main_path = get_main_path

    arch = ENV["ANDROID_ABI"].split(",")

    for a in arch
        build_glog a
    end
end

