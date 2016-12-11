#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
HASH="$(git log --pretty=format:%h -n 1)"
FILE=ddr-$2-$1-$COUNT-$HASH.zip
LATEST=ddr-latest-$2-$1.zip
HOST=$3
USER=$4
PASS=$5

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Compile ddr plugins"
for file in addons/sourcemod/scripting/ddr*.sp
do
  addons/sourcemod/scripting/spcomp -E -v0 $file
done

echo "Compile 3rd-party-plugins"
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/no_weapon_fix.sp

echo "Remove plugins folder if exists"
if [ -d "addons/sourcemod/plugins" ]; then
  rm -r addons/sourcemod/plugins
fi

echo "Create clean plugins folder"
mkdir addons/sourcemod/plugins
mkdir addons/sourcemod/plugins/ddr

echo "Move all ddr binary files to plugins folder"
for file in ddr*.smx
do
  mv $file addons/sourcemod/plugins/ddr
done

echo "Move all other binary files to plugins folder"
for file in *.smx
do
  mv $file addons/sourcemod/plugins
done

echo "Remove build folder if exists"
if [ -d "build" ]; then
  rm -r build
fi

echo "Create clean build folder"
mkdir build

echo "Move addons, cfg and materials folder"
mv addons cfg materials models build/

echo "Remove sourcemod folders"
rm -r build/addons/metamod
rm -r build/addons/sourcemod/bin
rm -r build/addons/sourcemod/configs/geoip
rm -r build/addons/sourcemod/configs/sql-init-scripts
rm build/addons/sourcemod/configs/* 2> /dev/null
rm -r build/addons/sourcemod/data
rm -r build/addons/sourcemod/extensions
rm -r build/addons/sourcemod/gamedata
rm -r build/addons/sourcemod/scripting
rm -r build/addons/sourcemod/translations
rm build/addons/sourcemod/*.txt

echo "Add LICENSE to build package"
cp LICENSE build/

echo "Clean root folder"
rm sourcemod.tar.gz

echo "Go to build folder"
cd build

echo "Compress directories and files"
zip -9rq $FILE addons cfg materials models LICENSE

echo "Upload file"
lftp -c "open -u $USER,$PASS $HOST; put -O ddr/downloads/$2/ $FILE"

echo "Add latest build"
mv $FILE $LATEST

echo "Upload latest build"
lftp -c "open -u $USER,$PASS $HOST; put -O ddr/downloads/ $LATEST"
