#!/bin/bash

# ======================================================================================================================
# Dove folder
# ======================================================================================================================
dovefolder="$HOME/.dove"
if [ ! -e $dovefolder ]; then
  echo "Create dove folder: $dovefolder";
  mkdir -p $dovefolder;
fi;

# ======================================================================================================================
# Token
# ======================================================================================================================
if [[ -z $SECRET_TOKEN ]]; then
  SECRET_TOKEN="";
  if [[ ! -z $2 ]]; then
    SECRET_TOKEN=$2;
  fi;
fi;
if [[ ! -z $SECRET_TOKEN ]]; then
  echo "Token: ***";
fi;

# ======================================================================================================================
# releases.json
# ======================================================================================================================
releases_path="$dovefolder/releases.json";
if [ ! -e $releases_path ] || [ $(($(date "+%s")-$(date -r $releases_path "+%s" ))) -ge 600 ]; then
  echo "Download: releases.json";
  if [ -z $SECRET_TOKEN ]; then
    curl -o "$releases_path.tmp" \
        -s https://api.github.com/repos/pontem-network/move-tools/releases;
  else
    curl -o "$releases_path.tmp" \
        -H "Authorization: Bearer ${SECRET_TOKEN}" \
        -s https://api.github.com/repos/pontem-network/move-tools/releases;
  fi;
  mv "$releases_path.tmp" $releases_path;
fi;
# check release.json
message=$(jq ".message?" -r $releases_path);
if [[ ! -z $message ]]; then
  echo "Message: $message";
  rm $releases_path;
  exit 4;
fi

# ======================================================================================================================
# pre-release (prerelease=true)
# ======================================================================================================================
if [[ -z $DOVE_PRERELEASE ]]; then
  DOVE_PRERELEASE="false";
  if [[ ! -z $3 ]]; then
    DOVE_PRERELEASE=$3;
  fi;
else
  if [ $DOVE_PRERELEASE != "true" ] && [ $DOVE_PRERELEASE != "false" ]; then
    DOVE_PRERELEASE="false";
  fi;
fi;
echo "Pre-release: $DOVE_PRERELEASE";
select_prerelease="";
if [ $DOVE_PRERELEASE == "false" ]; then
  select_prerelease=".prerelease==false";
else
  select_prerelease=".";
fi
# ======================================================================================================================
# Dove version
# ======================================================================================================================
dove_version=""
if [[ ! -z $DOVE_VERSION ]]; then
  dove_version=$DOVE_VERSION;
elif [[ ! -z $1 ]]; then
  dove_version=$1;
fi;
if [[ $dove_version == "latest" || $dove_version == "new" || $dove_version == "last" || -z $dove_version ]]; then
  # Get the latest version
  dove_version=$(cat "$releases_path" | jq -r ".[] | select(${select_prerelease}) .tag_name" | head -n1);
  if [[ -z $dove_version ]]; then
        echo "{$dove_version|$DOVE_PRERELEASE} The specified version of dove was not found";
        exit 5;
  fi
else
  if [ ! $(cat "$releases_path" | jq ".[] | select(${select_prerelease} and .tag_name==\"${dove_version}\") .tag_name") ]; then
    echo "{$dove_version} The specified version of dove was not found";
    exit 1;
  fi;
fi;
echo "version: $dove_version";

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
# ======================================================================================================================
# Download
# ======================================================================================================================
filename="dove_${dove_version}-${download_type}"
file_path="$dovefolder/$filename"

download_url=$(cat "$releases_path" |
  jq -r ".[] | select(${select_prerelease} and .tag_name==\"${dove_version}\") .assets | .[] | select(.name|test(\"^dove-${dove_version}-${download_type}\")) | .browser_download_url")
if [ -z $download_url ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      download_url=$(cat "$releases_path" |
        jq -r ".[] | select(${select_prerelease} and .tag_name==\"${dove_version}\") .assets | .[] | select(.name|test(\"^dove-${dove_version}-mac-${HOSTTYPE}\")) | .browser_download_url")
  fi
  if [ -z $download_url ]; then
    echo "Releases \"dove-${dove_version}-${download_type}\" not found"
    exit 3
  fi
fi

if [ ! -e $file_path ]; then
  echo "Download: $download_url"
  if [ -z $SECRET_TOKEN ]; then
    curl -sL --fail \
      -H "Accept: application/octet-stream" \
      -o "$file_path.tmp" \
      -s $download_url
  else
    curl -sL --fail \
      -H "Accept: application/octet-stream" \
      -H "Authorization: Bearer ${SECRET_TOKEN}" \
      -o "$file_path.tmp" \
      -s $download_url
  fi
  mv "$file_path.tmp" $file_path
fi

echo "chmod 1755 $file_path"
chmod 1755 $file_path

echo "create link $file_path"
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
  mkdir -p $HOME/.local/bin
  ln -sf "$file_path" $HOME/.local/bin/dove
  echo "$HOME/.local/bin" >> $GITHUB_PATH
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
# ======================================================================================================================
# run
# ======================================================================================================================
echo "run: $file_path -V"
$file_path -V
