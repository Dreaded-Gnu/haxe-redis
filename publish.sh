#!/bin/sh
rm -f haxe-redis.zip
zip -r haxe-redis.zip src README.md CHANGELOG.md LICENSE.md haxelib.json
haxelib submit haxe-redis.zip DreadedGnu
