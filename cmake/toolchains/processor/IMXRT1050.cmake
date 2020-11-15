# This file should be included before other toolchain files in order to set flags and other variables
# Public Domain
#

if(IMXRT1050_FREERTOS_TOOLCHAIN_INCLUDED)
	return()
endif()
set(IMXRT1050_FREERTOS_TOOLCHAIN_INCLUDED true)

include(cm7)
# 1050-specific variables should be added to this file
