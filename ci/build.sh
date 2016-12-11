#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
HASH="$(git log --pretty=format:%h -n 1)"
FILE=ttt-$2-$1-$COUNT-$HASH.zip
LATEST=ttt-latest-$2-$1.zip
HOST=$3
USER=$4
PASS=$5

echo "Remove build folder if exists"
if [ -d "tmp" ]; then
  rm -r tmp
fi

echo "Create tmp folder"
mkdir tmp
cd tmp

echo "Download und extract sourcemod"
wget -q "http://www.sourcemod.net/latest.php?version=$1&os=linux" -O sourcemod.tar.gz
# wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Move compiler"
cd ..
cp -Rf tmp/addons/sourcemod/scripting/spcomp addons/sourcemod/scripting/spcomp

echo "Override include folders"
cp -Rf tmp/addons/sourcemod/scripting/include/ addons/sourcemod/scripting/

echo "Remove tmp folder"
rm -R tmp

echo "Give compiler rights"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugin version"
for file in addons/sourcemod/scripting/*.sp
do
  sed -i "s/<ID>/$COUNT/g" $file > output.txt
  rm output.txt
done

echo "Compile plugins"
for file in addons/sourcemod/scripting/*.sp
do
  addons/sourcemod/scripting/spcomp -E -v0 $file
done

echo "Remove compiler"
rm addons/sourcemod/scripting/spcomp

echo "Remove plugins folder if exists"
if [ -d "addons/sourcemod/plugins" ]; then
  rm -r addons/sourcemod/plugins
fi

echo "Create clean plugins folder"
mkdir addons/sourcemod/plugins

echo "Move all binary files to plugins folder"
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

echo "Move addons and materials folder"
mv addons cfg materials models build/

echo "Go to build folder"
cd build

echo "Compress directories and files"
zip -9rq $FILE addons materials sound

echo "Upload file"
lftp -c "open -u $USER,$PASS $HOST; put -O downloads/$2/ $FILE"

echo "Add latest build"
mv $FILE $LATEST

echo "Upload latest build"
lftp -c "open -u $USER,$PASS $HOST; put -O downloads/ $LATEST"

