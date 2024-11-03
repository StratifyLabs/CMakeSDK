"""

"""

load("spaces-starlark-sdk/packages/Kitware/CMake/v3.30.5.star", cmake3_platforms = "platforms")
load("spaces-starlark-sdk/packages/ninja-build/ninja/v1.12.1.star", ninja1_platforms = "platforms")

load("spaces-starlark-sdk/star/cmake.star", "add_cmake")


add_cmake(
    rule_name = "cmake3",
    platforms = cmake3_platforms
)

checkout.add_platform_archive(
    rule = {"name": "ninja1"},
    platforms = ninja1_platforms
)


checkout.update_asset(
    rule = {"name": "update_vscode_extensions"},
    asset = {
        "destination": ".vscode/extensions.json",
        "format": "json",
        "value": {
            "recommendations": ["llvm-vs-code-extensions.vscode-clangd", "ms-vscode.cmake-tools"],
        },
    },
)

checkout.update_asset(
    rule = {"name": "update_vscode_settings"},
    asset = {
        "destination": ".vscode/settings.json",
        "format": "json",
        "value": {
            "cmake.buildDirectory": "${workspaceFolder}/cmake_arm",
            "cmake.cmakePath": "${workspaceFolder}/sysroot/bin/cmake",
            "cmake.generator": "Ninja",
            "cmake.buildTask": True,
            "cmake.configureOnEdit": False,
            "cmake.loadCompileCommands": True,
            "cmake.useCMakePresets": "never",
            "cmake.buildEnvironment": {"PATH": "${workspaceFolder}/sysroot/bin"},
        },
    },
)

local_path = info.current_workspace_path()

checkout.add_asset(
    rule = {"name": "clang-format-config"},
    asset = {
        "destination": ".clang-format",
        "content": fs.read_file_to_string("{}/spaces_assets/clang-format".format(local_path)),
    },
)

checkout.add_asset(
    rule = {"name": "clangd-config"},
    asset = {
        "destination": ".clangd",
        "content": fs.read_file_to_string("{}/spaces_assets/clangd.json".format(local_path)),
    },
)

checkout.add_repo(
    rule = {"name": "tools/sysroot-cmake"},
    repo = {
        "url": "https://github.com/work-spaces/sysroot-cmake",
        "rev": "v3",
        "checkout": "Revision",
    },
)

checkout.add_repo(
    rule = {"name": "tools/sysroot-ninja"},
    repo = {"url": "https://github.com/work-spaces/sysroot-ninja", "rev": "v1", "checkout": "Revision"},
)

checkout.add_archive(
    rule = {"name": "stratifyos_arm_none_eabi"},
    archive = {
        "url": "https://github.com/StratifyLabs/SDK/releases/download/v11.3.1/stratifyos-arm-none-eabi-11.3.1.zip",
        "sha256": "d32b82768b4d6c1f106a32182b386164fccd72863c7d558b3fef129281780ac4",
        "link": "Hard",
        "add_prefix": "sysroot",
    },
)

sl_includes = ["sl"]
macos_sl_universal = {
    "url": "https://github.com/StratifyLabs/sl2/releases/download/v2.0/sl-macos-x86_64.zip",
    "sha256": "5c8f84c23655b6de4222bd4df72a399f3a53efc367bed5ed0db9e9320014ee92",
    "add_prefix": "sysroot/bin",
    "includes": sl_includes,
    "link": "Hard",
}

checkout.add_platform_archive(
    rule = {"name": "sl"},
    platforms = {
        "macos-x86_64": macos_sl_universal,
        "macos-aarch64": macos_sl_universal,
        "windows-x86_64": {
            "url": "https://github.com/StratifyLabs/sl2/releases/download/v2.0/sl-windows-x86_64.zip",
            "sha256": "5787d28ee13013cbf5d848b8cd3c115087735781375934e848fa917436031f2a",
            "add_prefix": "sysroot/bin",
            "includes": sl_includes,
            "link": "Hard",
        },
    },
)

bin_excludes = ["**/bin/sl"]

macos_arm_none_eabi_universal = {
    "url": "https://github.com/StratifyLabs/SDK/releases/download/v11.3.1/stratifyos-arm-none-eabi-11.3.1-macos-x86_64.zip",
    "sha256": "c58c383fdb95f538fda6bc0484f04500d2acce64d08db18f775e04b2ee3e1746",
    "add_prefix": "sysroot",
    "excludes": bin_excludes,
    "link": "Hard",
}

checkout.add_platform_archive(
    rule = {"name": "stratifyos_arm_none_eabi_platform", "deps": ["stratifyos_arm_none_eabi"]},
    platforms = {
        "macos-x86_64": macos_arm_none_eabi_universal,
        "macos-aarch64": macos_arm_none_eabi_universal,
        "windows-x86_64": {
            "url": "https://github.com/StratifyLabs/SDK/releases/download/v11.3.1/stratifyos-arm-none-eabi-11.3.1-windows-x86_64.zip",
            "sha256": "2b56314049456bec812405d168fd5ab62e414817bea167f10d12889ae1b2fbe5",
            "add_prefix": "sysroot",
            "excludes": bin_excludes,
            "link": "Hard",
        },
    },
)
