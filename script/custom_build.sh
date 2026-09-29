#!/usr/bin/env bash

LV_VER="9.6.0"
MP_VER="1.30.0-preview"
IDF_VER="5.5.5"
BUILD_TAGS=mp$MP_VER"_lv$LV_VER"_idf$IDF_VER
BUILD_PATH=firmwares/$BUILD_TAGS
mkdir $BUILD_PATH

<<patches
# to build with lv9.1.1
# api_drivers/py_api_drivers/frozen/indev/touch_calibration/touch_calibrate.py:83 [lv.SCREEN_LOAD_ANIM -> lv.SCR_LOAD_ANIM]
git update-index --cacheinfo 160000,657fccd132ea1028d4d28964867fbd02373afc76,lib/lvgl

# on lv9.6.0 to fix ValueError: invalid literal for int() with base 16: '0xX1FFFFFFF'
# in "lib/lvgl/scripts/gen_json/pycparser_monkeypatch.py", line 412, in to_dict
# f'0x{hex(int(member["value"], 16))[2:].zfill(hex_len).upper()}'
cp script/pycparser_monkeypatch.py lib/lvgl/scripts/gen_json/pycparser_monkeypatch.py

# apply PR task_handler: fix LVGL time running ~2x fast (double tick_inc)- #607
wget -O api_drivers/common_api_drivers/frozen/other/task_handler.py \
https://raw.githubusercontent.com/bitcoin3us/lvgl_micropython/333c680c9aa8e9f6e296754e13776719186c4ec0/api_drivers/common_api_drivers/frozen/other/task_handler.py
patches

DRIVERS="DISPLAY=GC9A01 DISPLAY=ST7735 DISPLAY=st7789 DISPLAY=ili9341 DISPLAY=ili9488 INDEV=xpt2046"

python3 make.py esp32 clean BOARD=ESP32_GENERIC_S3 BOARD_VARIANT=SPIRAM_OCT --flash-size=16 --enable-uart-repl=n --enable-cdc-repl=y --enable-jtag-repl=n $DRIVERS &&\
mv build/lvgl_micropy_ESP32_GENERIC_S3-SPIRAM_OCT-16.bin $BUILD_PATH/ESP32_GENERIC_S3-SPIRAM_OCT-CDC-16M_$BUILD_TAGS.bin &&\

cp lvgl.pyi stubs/lvgl_$LV_VER.pyi &&\

python3 make.py esp32 clean BOARD=LOLIN_S2_MINI --enable-uart-repl=n --enable-cdc-repl=y --enable-jtag-repl=n $DRIVERS &&\
mv build/lvgl_micropy_LOLIN_S2_MINI-4.bin $BUILD_PATH/LOLIN_S2_MINI-4M_$BUILD_TAGS.bin &&\

python3 make.py esp32 clean BOARD=ESP32_GENERIC_C3 --enable-uart-repl=n --enable-cdc-repl=n --enable-jtag-repl=y $DRIVERS &&\
mv build/lvgl_micropy_ESP32_GENERIC_C3-4.bin $BUILD_PATH/ESP32_GENERIC_C3-4M_$BUILD_TAGS.bin &&\

python3 make.py esp32 clean BOARD=ESP32_GENERIC --optimize-size DISPLAY=ili9341 INDEV=xpt2046 &&\
mv build/lvgl_micropy_ESP32_GENERIC-4.bin $BUILD_PATH/ESP32_GENERIC-4M_$BUILD_TAGS.bin &&\

python3 make.py esp32 clean BOARD=ESP32_GENERIC_S3 BOARD_VARIANT=SPIRAM_OCT --flash-size=16 --enable-uart-repl=y --enable-cdc-repl=n --enable-jtag-repl=n $DRIVERS &&\
mv build/lvgl_micropy_ESP32_GENERIC_S3-SPIRAM_OCT-16.bin $BUILD_PATH/ESP32_GENERIC_S3-SPIRAM_OCT-UART-16M_$BUILD_TAGS.bin