# v2.1.0

## New Features

- Updated `cmsdk2` functions with named arguments for BSP, LIB and APP

# v2.0.0

## New Features

- Refactored from `sos-sdk` to `cmsdk`

# v1.3.0

## New Features

- None yet

## Bug Fixes

- Use `git pull` before `git checkout` when building the pull target

# v1.2.0

## New Features

- Remove MacOs min version settings - top level must use `CMAKE_OSX_DEPLOYMENT_TARGET`
- Update `sdk/api.h` with ECC crypto functions
- Add Windows compiler downlaod via github with SHA256
- Add MacOS and Linux compiler download via github with SHA256 hash
- Add ECC to the crypt API

## Bug Fixes

- Better management of `git checkout <branch>` and `git pull`

# v1.1.0

## New Features

- Add `scripts/sl.cmake` to install sl and a clean compiler
- Add `scripts/profile.sh` to set the ENV variables from a project
- add `cmsdk_copy_file` to copy a file without overwriting
- add `cmsdk_overwrite_file` to copy a file with overwriting
- add `cmsdk_git_clone_or_pull` to pull subprojects

## Bug Fixes

- Fixed `CMSDK_IS_LINUS` bug (backwards compatible fix) (f09467eb421e3a57dfbc0c8b6ef2f2520ffd4617)

# v1.0.0

Initial Stable Release
