include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = MIPSCPU
MIPSCPU_OBJC_FILES = \
	MIPSCPU/MIPSCPU.m \
	MIPSCPU/MIPSCtx.m

#NOWARN=-Wno-format -Wno-return-type -Wno-unused-value -Wno-unused-variable -Wno-self-assign
MIPSCPU_OBJCFLAGS=$(NOWARN) \
	-I${HOME}/GNUstep/Library/ApplicationSupport/Hopper/HopperSDK/include \
	-I./capstone/include/ \
	-DLINUX

include $(GNUSTEP_MAKEFILES)/bundle.make
