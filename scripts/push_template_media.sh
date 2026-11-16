#!/usr/bin/env bash
# Copies a few clips + photos from the phone's camera roll into the app's
# private documents dir (tpl_media) for integration_test/templates_test.dart.
export MSYS_NO_PATHCONV=1
A="${ADB:-/c/Users/DELL/AppData/Local/Android/Sdk/platform-tools/adb.exe}"
APP=com.ayushstudio.clipforge
D=/data/user/0/$APP/app_flutter/tpl_media
"$A" shell "rm -rf /data/local/tmp/tpl && mkdir -p /data/local/tmp/tpl"
"$A" shell "cd /sdcard/DCIM/Camera && for f in 20260616_145119.mp4 20260616_153904.mp4 20260616_153817.mp4 20260616_153751.mp4; do cp \$f /data/local/tmp/tpl/\$f; done; i=0; for f in \$(ls *.jpg | head -6); do cp \$f /data/local/tmp/tpl/\$f; done"
"$A" shell "chmod -R 755 /data/local/tmp/tpl"
"$A" shell "run-as $APP sh -c 'rm -rf $D; mkdir -p $D; cp /data/local/tmp/tpl/* $D/'"
"$A" shell "run-as $APP ls $D"
