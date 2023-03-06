#!/usr/bin/env ruby

require "fileutils"
require "pty"
require "yaml"
require "optparse"

def get_main_path
    File.dirname(File.realdirpath(caller[0].match(/^(.*?):/)[1]))
end

def get_canonicalized_root_src (fp)
    File.realpath(fp, $main_path)
end

def get_sdk_cmake
    android_sdk_cmake_bin = "#{ENV["ANDROID_SDK_ROOT"]}/cmake/#{ENV["ANDROID_SDK_CMAKE_VERSION"]}/bin"
    "#{android_sdk_cmake_bin}/cmake"
end

def get_sdk_ninja
    android_sdk_cmake_bin = "#{ENV["ANDROID_SDK_ROOT"]}/cmake/#{ENV["ANDROID_SDK_CMAKE_VERSION"]}/bin"
    "#{android_sdk_cmake_bin}/ninja"
end

def get_abi_list
    ENV["ANDROID_ABI"].split(",")
end

def get_cmake_toolchain
    "#{ENV["ANDROID_NDK_ROOT"]}/build/cmake/android.toolchain.cmake"
end

def with_android_env
    return get_sdk_cmake, get_sdk_ninja, get_abi_list
end

def cmd (cmd, exception_msg = "")
    begin
        PTY.spawn(cmd) do |stdout, stdin, pid|
          begin
            stdout.each { |line| print line }
          rescue Errno::EIO
          end
        end
      rescue PTY::ChildExited
        puts "The child process exited!"
      end
end

def download_file(base_url, filename, sha256)
  sha256_now = `sha256sum #{filename}`[0..63] if File.exist?(filename)
  if sha256 == sha256_now
    puts "File already exists and the SHA256 matches."
  else
    cmd("curl -LO #{File.join(base_url, filename)}", "Error downloading file: ")
    sha256_now = `sha256sum #{filename}`[0..63]
    if sha256 == sha256_now
      puts "File downloaded and the SHA256 matches."
    else
      raise "SHA256 mismatched: expected #{sha256}, but got #{sha256_now}."
    end
  end
end

def check_env (variable, exception_msg)
    if not ENV.include?(variable)
        raise ArgumentError, exception_msg
    end
end

def get_config
    begin
        YAML.load_file("#{$main_path}/build.yaml")
    rescue YAML::SyntaxError => ex
        ex.file
        ex.message
    end
end


def build_glog ()
    cmake, ninja, abi_list = with_android_env
    toolchain = get_cmake_toolchain

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)
    glog_src = get_canonicalized_root_src "glog"
    for a in abi_list
        Dir.chdir(glog_src)
        build_dir = "build_#{a}"
        install_dir = "#{out}/glog/#{a}"

        if Dir.exist?(build_dir)
            puts ">>> Cleaning previous build intermediates"
            FileUtils.rm_r(build_dir)
        end

        puts ">>> Building glog for #{a}"
        cmd(""" \
            #{cmake} -B#{build_dir} -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=#{toolchain} \
            -DCMAKE_MAKE_PROGRAM=#{ninja} \
            -DANDROID_ABI=#{a} \
            -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
            -DANDROID_STL=c++_shared \
            -DCMAKE_INSTALL_PREFIX=#{install_dir} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=OFF \
            -DWITH_GFLAGS=OFF \
            -DWITH_GTEST=OFF \
            -DWITH_UNWIND=OF \
            -DBUILD_TESTING=OFF""")
        cmd("#{cmake} --build #{build_dir} --target install")
    
        pkgconfig_path = "#{install_dir}/lib/pkgconfig"
        FileUtils.rm_r(pkgconfig_path) if Dir.exist?(pkgconfig_path)
    end
    Dir.chdir(out)
end

def build_leveldb ()
    cmake, ninja, abi_list = with_android_env
    toolchain = get_cmake_toolchain

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)
    leveldb_src = get_canonicalized_root_src "leveldb"
    for a in abi_list
        Dir.chdir(leveldb_src)
        build_dir = "build_#{a}"
        install_dir = "#{out}/leveldb/#{a}"

        if Dir.exist?(build_dir)
            puts ">>> Cleaning previous build intermediates"
            FileUtils.rm_r(build_dir)
        end

        puts ">>> Building leveldb for #{a}"
        cmd(""" \
            #{cmake} -B#{build_dir} -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=#{toolchain} \
            -DCMAKE_MAKE_PROGRAM=#{ninja} \
            -DANDROID_ABI=#{a} \
            -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
            -DANDROID_STL=c++_shared \
            -DCMAKE_INSTALL_PREFIX=#{install_dir} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=OFF \
            -DLEVELDB_BUILD_BENCHMARKS=OFF \
	        -DLEVELDB_BUILD_TESTS=OFF""")
        cmd("#{cmake} --build #{build_dir} --target install")
    
        pkgconfig_path = "#{install_dir}/lib/pkgconfig"
        FileUtils.rm_r(pkgconfig_path) if Dir.exist?(pkgconfig_path)
    end
    Dir.chdir(out)
end

def build_lua ()
    cmake, ninja, abi_list = with_android_env
    toolchain = get_cmake_toolchain

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)
    lua_src = get_canonicalized_root_src "Lua"
    for a in abi_list
        Dir.chdir(lua_src)
        build_dir = "build_#{a}"
        install_dir = "#{out}/lua/#{a}"

        if Dir.exist?(build_dir)
            puts ">>> Cleaning previous build intermediates"
            FileUtils.rm_r(build_dir)
        end

        puts ">>> Building Lua for #{a}"
        cmd(""" \
            #{cmake} -B#{build_dir} -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=#{toolchain} \
            -DCMAKE_MAKE_PROGRAM=#{ninja} \
            -DANDROID_ABI=#{a} \
            -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
            -DANDROID_STL=c++_shared \
            -DCMAKE_INSTALL_PREFIX=#{install_dir} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=OFF \
            -DLUA_BUILD_BINARY=OFF \
            -DLUA_BUILD_COMPILER=OFF""")
        cmd("#{cmake} --build #{build_dir} --target install")
    
        pkgconfig_path = "#{install_dir}/lib/pkgconfig"
        FileUtils.rm_r(pkgconfig_path) if Dir.exist?(pkgconfig_path)
    end
    Dir.chdir(out)
end

def build_marisa_trie ()
    cmake, ninja, abi_list = with_android_env
    toolchain = get_cmake_toolchain

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)
    marisa_trie_src = get_canonicalized_root_src "marisa-trie"
    # Symlink CMakeLists.txt
    FileUtils.ln_sf("#{$main_path}/support/marisa-trie/CMakeLists.txt", "#{marisa_trie_src}/CMakeLists.txt")

    for a in abi_list
        Dir.chdir(marisa_trie_src)
        build_dir = "build_#{a}"
        install_dir = "#{out}/marisa-trie/#{a}"

        if Dir.exist?(build_dir)
            puts ">>> Cleaning previous build intermediates"
            FileUtils.rm_r(build_dir)
        end

        puts ">>> Building marisa-trie for #{a}"
        cmd(""" \
            #{cmake} -B#{build_dir} -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=#{toolchain} \
            -DCMAKE_MAKE_PROGRAM=#{ninja} \
            -DANDROID_ABI=#{a} \
            -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
            -DANDROID_STL=c++_shared \
            -DCMAKE_INSTALL_PREFIX=#{install_dir} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=OFF""")
        cmd("#{cmake} --build #{build_dir} --target install")
    
        pkgconfig_path = "#{install_dir}/lib/pkgconfig"
        FileUtils.rm_r(pkgconfig_path) if Dir.exist?(pkgconfig_path)
    end
    Dir.chdir(out)
end

def build_yaml_cpp ()
    cmake, ninja, abi_list = with_android_env
    toolchain = get_cmake_toolchain

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)
    yaml_cpp_src = get_canonicalized_root_src "yaml-cpp"
    for a in abi_list
        Dir.chdir(yaml_cpp_src)
        build_dir = "build_#{a}"
        install_dir = "#{out}/yaml-cpp/#{a}"

        if Dir.exist?(build_dir)
            puts ">>> Cleaning previous build intermediates"
            FileUtils.rm_r(build_dir)
        end

        puts ">>> Building yaml-cpp for #{a}"
        cmd(""" \
            #{cmake} -B#{build_dir} -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=#{$cmake_toolchain} \
            -DCMAKE_MAKE_PROGRAM=#{ninja} \
            -DANDROID_ABI=#{a} \
            -DANDROID_PLATFORM=#{ENV["ANDROID_PLATFORM"]} \
            -DANDROID_STL=c++_shared \
            -DCMAKE_INSTALL_PREFIX=#{install_dir} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=OFF \
            -DYAML_CPP_BUILD_CONTRIB=OFF \
	        -DYAML_CPP_BUILD_TESTS=OFF \
	        -DYAML_CPP_BUILD_TOOLS=OFF""")
        cmd("#{cmake} --build #{build_dir} --target install")
    
        pkgconfig_path = "#{install_dir}/share/pkgconfig"
        FileUtils.rm_r(pkgconfig_path) if Dir.exist?(pkgconfig_path)
    end
    Dir.chdir(out)
end

def build_boost ()
    _, _, abi_list = with_android_env

    out = File.realpath(Dir.pwd)
    Dir.chdir(out)

    # Download the source
    boost_config = get_config["boost"]
    boost_base_url = boost_config["base_url"]
    boost_version = boost_config["version"]
    boost_sha256 = boost_config["sha256"]
    boost_filename = "boost_#{boost_version.gsub(".", "_")}"
    boost_tar = "#{boost_filename}.tar.bz2"
    download_file boost_base_url.gsub("${boost_version}", boost_version), boost_tar, boost_sha256

    boost_android_src = get_canonicalized_root_src "Boost-for-Android"
    install_dir = "#{out}/boost"
    # The build script will test if the prefix dir exist,
    # if true, then install (copy) the artifacts in the prefix dir,
    # so let's make the dir first.
    FileUtils.mkdir_p(install_dir)

    # Download the libiconv build scripts in advance
    # to modify APILEVEL
    libiconv_android_src = "libiconv-libicu-android"
    cmd("git clone --depth=1 https://github.com/pelya/#{libiconv_android_src}.git") \
        if not Dir.exist?("#{out}/#{libiconv_android_src}")
    for a in abi_list
        cmd("""sed -e \'s/^APILEVEL=[0-9][0-9]$/APILEVEL=#{ENV["ANDROID_PLATFORM"]}/g\' \
            -i #{out}/#{libiconv_android_src}/setEnvironment-#{a}.sh""")
    end

    cmd("""#{boost_android_src}/build-android.sh \
        --prefix=#{install_dir} \
        --boost=#{boost_version} \
        --with-libraries=filesystem,regex,system,locale \
        --arch=#{abi_list.join(",")} \
        --target-version=#{ENV["ANDROID_PLATFORM"]} \
        --layout=system \
        #{ENV["ANDROID_NDK_ROOT"]}""")
    
    # since header files are the same regardless of abi
    # we take a random one
    first_abi = abi_list[0]
    FileUtils.cp_r("#{out}/boost/#{first_abi}/include", "#{out}/boost/.")
    for a in abi_list
        # symlink headers for each abi to reduce size
        include_path = "#{out}/boost/#{a}/include"
        FileUtils.rm_r(include_path) if Dir.exist?(include_path)
        FileUtils.ln_sf("../include", include_path)
    end
    Dir.chdir(out)
end

if __FILE__ == $0
    $main_path = get_main_path

    action_hash = {
        "glog" => :build_glog,
        "leveldb" => :build_leveldb,
        "lua" => :build_lua,
        "marisa-trie" => :build_marisa_trie,
        "yaml-cpp" => :build_yaml_cpp,
        "boost" => :build_boost
    }

    OptionParser.new do |parser|
        parser.banner = "Usage: prebuilt.rb [options]"

        parser.on("-b", "--build COMPONENT", "Build specified component.") do |com|
            check_env "ANDROID_SDK_ROOT", "ANDROID_SDK_ROOT should be set to Android SDK path."
            check_env "ANDROID_NDK_ROOT", "ANDROID_NDK_ROOT should be set to Android NDK path."
            check_env "ANDROID_SDK_CMAKE_VERSION", \
                "ANDROID_SDK_CMAKE_VERSION should be set to desired cmake version in $ANDROID_SDK_ROOT/cmake. eg. 3.18.1"
            check_env "ANDROID_PLATFORM", \
                "ANDROID_PLATFORM should be set to minimum API level supported by the library. eg. 21"
            check_env "ANDROID_ABI", "ANDROID_ABI not set; can be a ',' separated list. eg. armeabi-v7a,arm64-v8a"

            if action_hash.include?(com)
                send(action_hash[com])
            elsif com == "everything"
                action_hash.each { |_, act| send(act) }
            else
                puts "Unknown component: '#{com}'."
                puts "Run `prebult.rb -l` to see available components."
            end
        end

        parser.on("-l", "--list", "List all available components.") do
            puts "Available components: #{action_hash.keys.join(", ")}"
            puts "Run `prebuilt.rb -b everything` to build all components."
            exit
        end

        parser.on("-h", "--help", "Prints this help.") do
            puts parser
            exit
        end
    end.parse!
end

