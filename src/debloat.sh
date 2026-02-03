#!/usr/bin/env bash


self_pid=$$

display_help(){
  echo "Usage: $0 <json file> [adb options]" >&2
  exit 1
}

trap display_help SIGINT

terminate(){
  kill -s SIGINT $self_pid 
  exit 1
}

yes_confirm(){
  ask="$1"
  read -rp "$ask [Y/n] " confirm

  if [[ "$confirm" == "N" || "$confirm" == "n" ]]; then
    return 1
  fi
}

no_confirm(){
  ask="$1"
  read -rp "$ask [y/N] " confirm

  if ! [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
    return 1
  fi
}

json_file="$1"
shift

adb_args="$*"
adbc(){
  args="$*"
  adb $adb_args $args
  return $?
}

init_checks(){
if [ ! -f "$json_file" ]; then
  echo "json file $json_file not found!" >&2
  terminate
fi




if ! adbc shell command -v pm >/dev/null; then
  echo "Couldn't access device's package manager through 'adb $adb_args shell'. Are you sure the device is connected and/or the options are right?" >&2
  terminate
fi

device="$(adbc shell getprop 'ro.product.model')"

echo "[Device]: $device"
echo "[PM access]: OK"
echo "[JSON]: $json_file"
}


# need_disable are the common packages between device and json.
need_disable=()

select_packages(){

mapfile -t device_packages <<< "$(adbc shell pm list packages --user 0 -e | cut -d ':' -f2)"
mapfile -t json_packages <<< "$(jq -r '.[].Package' "$json_file")"

for jp in "${json_packages[@]}"; do
  for dp in "${device_packages[@]}"; do
    if [ "$jp" = "$dp" ]; then 
      need_disable+=("$dp")
    fi
  done
done

mapfile -t need_disable <<< "$(echo "${need_disable[@]}" | tr ' ' '\n' |  sort | uniq)"

if [ ${#need_disable[@]} -eq 0 ]; then
  echo "No package needs to be disabled. Your device is unbloated :)"
  exit 0
fi

}


disable_packages(){

 while true; do 
  echo "Disabling the following packages of $device:"

for i in "${!need_disable[@]}"; do
  jq -r --arg name "${need_disable[i]}" --arg i "$((i+1))" '. | map(select(.Package == $name)) | "[\($i)] " + (map(.Name) | unique | join(", ")) + " -> " + (map(.Package) | unique | join(", "))' "$json_file"
done

if ! no_confirm "Do you want to continue?"; then

# TODO: Store the user prefs about saved packages and ignores them automatically
  if no_confirm "Do you want to choose which apps will be saved from debloat?"; then
    read -rp "Select each app by its number. Split them by space: " -a app_numbers

    for i in "${app_numbers[@]}"; do
      need_disable[i-1]=""
    done

    read -ra need_disable <<< "${need_disable[@]}"

  else
    return 1
  fi

else
  break
fi

done

  for package in "${need_disable[@]}"; do

    echo "Disabling \"$package\"..."

    if ! (adbc shell pm disable --user 0 "$package" || adbc shell pm disable-user --user 0 "$package"); then
      if yes_confirm "\"$package\" cannot be disabled. Try to uninstall it?"; then
        adbc shell pm uninstall -k --user 0 "$package" || echo "error uninstalling \"$package\"!"
      fi
    fi

  done

}


init_checks
select_packages
disable_packages



