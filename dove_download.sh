#!/bin/bash

basefolder="$HOME/.dove"

if [ ! -e $basefolder ]; then
  echo "create dove folder: $basefolder"
  mkdir -p $basefolder;
fi
releases_path="$basefolder/releases.json"

if [ ! -e $releases_path ] || [ $(expr $(stat -c %Y "$releases_path") + 600) -le $(date +%s) ]; then
  echo "Download: releases.json"
  curl -o "$releases_path" \
      -s https://api.github.com/repos/pontem-network/move-tools/releases
fi

dove_version=""
if [[ $1 == "latest" || $1 == "new" || $1 == "last" || -z $1 ]]; then
  dove_version=$(cat "$releases_path" | jq -r '.[0] .tag_name')
else
  if [ ! $(cat "$releases_path" |
    jq ".[] | select(.tag_name==\"${1}\") .tag_name") ]; then
    echo "{$1} The specified version of dove was not found"
    exit 1
  fi
  dove_version=$1
fi

if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
  download_type="linux-$HOSTTYPE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  download_type="darwin-$HOSTTYPE"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  download_type="win-$HOSTTYPE.exe"
else
  echo "Unknown OS"
  exit 2
fi

filename="dove_${dove_version}-${download_type}"
file_path="$basefolder/$filename"

download_url=$(cat "$releases_path" |
  jq -r ".[] | select(.tag_name==\"${dove_version}\") .assets | .[] | select(.name|test(\"^dove-${dove_version}-${download_type}\")) | .browser_download_url")
if [ -z $download_url ]; then
  echo "Releases \"dove-${dove_version}-${download_type}\" not found"
  exit 3
fi

if [ ! -e $file_path ]; then
  echo "Download: $download_url"
  curl -sL --fail \
    -H "Accept: application/octet-stream" \
    -o $file_path \
    -s $download_url
fi

echo "chmod 1755 $file_path"
chmod 1755 $file_path

echo "create link $file_path"
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
  mkdir -p $HOME/.local/bin
  ln -sf "$file_path" $HOME/.local/bin/dove
elif [[ "$OSTYPE" == "darwin"* ]]; then
  ln -sf "$file_path" /usr/local/bin/dove
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$file_path" "$HOME/.local/bin/dove"
  echo "$HOME/.local/bin" >> $GITHUB_PATH
else
  echo "Unknown OS"
  exit 2
fi

echo "run: $file_path -V"
$file_path -V
