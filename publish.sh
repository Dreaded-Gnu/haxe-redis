#!/bin/sh
rm -f redislib.zip
zip -r redislib.zip src README.md CHANGELOG.md LICENSE.md haxelib.json
haxelib submit redislib.zip
