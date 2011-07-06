export THEOS_DEVICE_IP=192.168.2.6
include theos/makefiles/common.mk

TWEAK_NAME = BookmarksBarEnhancer
BookmarksBarEnhancer_FILES = Tweak.xm SA_ActionSheet.m
BookmarksBarEnhancer_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
