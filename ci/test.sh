#!/bin/bash

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

echo "Compile plugins"
for file in addons/sourcemod/scripting/*.sp
do
  addons/sourcemod/scripting/spcomp -E -v0 $file
done
