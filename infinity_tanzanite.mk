#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/infinity/config/common_full_phone.mk)

# Inherit from tanzanite device
$(call inherit-product, device/xiaomi/tanzanite/device.mk)

# Enable UI enhancements
TARGET_ENABLE_BLUR := false
PERF_ANIM_OVERRIDE := true

# Enable features
TARGET_SUPPORTS_QUICK_TAP := true
BYPASS_CHARGE_SUPPORTED := true
TARGET_FACE_UNLOCK_SUPPORTED := true
USE_PIXEL_CHARGING := true

# Maintainer Name
INFINITY_MAINTAINER := Yaseakun

# Whether the device supports Fingerprint On Display
TARGET_HAS_UDFPS := true

# Whether Including Google Apps
WITH_GAPPS := true

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := tanzanite
PRODUCT_NAME := infinity_tanzanite
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24117RN76O
PRODUCT_MANUFACTURER := xiaomi

PRODUCT_BRAND_FOR_ATTESTATION := $(PRODUCT_BRAND)
PRODUCT_DEVICE_FOR_ATTESTATION := $(PRODUCT_DEVICE)
PRODUCT_MODEL_FOR_ATTESTATION := $(PRODUCT_MODEL)
PRODUCT_NAME_FOR_ATTESTATION := tanzanite_eea
PRODUCT_MANUFACTURER_FOR_ATTESTATION := $(PRODUCT_MANUFACTURER)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Redmi/tanzanite_eea/tanzanite:15/AP3A.240905.015.A2/OS2.0.214.0.VOGEUXM:user/release-keys \
    BuildDesc="missi-user 15 AP3A.240905.015.A2 OS2.0.214.0.VOGEUXM release-keys" \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME) \
    SystemDevice=$(PRODUCT_SYSTEM_DEVICE) \
    SystemName=$(PRODUCT_SYSTEM_NAME)
