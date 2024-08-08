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


adbc shell command -v pm >/dev/null


if [ $? -ne 0 ]; then
  echo "Couldn't access device's package manager through 'adb $adb_args shell'. Are you sure the device is connected and/or the options are right?" >&2
  terminate
fi

echo "[Device]: $(adbc shell getprop 'ro.product.model')"
echo "[PM access]: OK"
echo "[JSON]: $json_file"
}


# need_disable are the common packages between device and json.
need_disable=()

select_packages(){

device_packages=(`adbc shell pm list packages --user 0 -e | cut -d ':' -f2`)
json_packages=($(jq -r '.[].Package' $json_file))


for jp in "${json_packages[@]}"; do
  for dp in "${device_packages[@]}"; do
    if [ "$jp" = "$dp" ]; then 
      need_disable+=("$dp")
    fi
  done
done

need_disable=($(echo "${need_disable[@]}" | tr ' ' '\n' |  sort | uniq))

if [ ${#need_disable[@]} -eq 0 ]; then
  echo "No package needs to be disabled. Your device is unbloated :)"
  exit 0
fi

}


disable_packages(){

echo "Disabling the following packages of" `adbc shell getprop 'ro.product.model'`":"

for name in "${need_disable[@]}"; do
  jq -r --arg name $name '. | map(select(.Package == $name)) | "" + (map(.Name) | unique | join(", ")) + " -> " + (map(.Package) | unique | join(", "))' "$json_file"
done

read -p "Do you want to continue? [s/N] " confirm
if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
  for package in "${need_disable[@]}"; do

    echo "Disabling \"$package\"..."

    adbc shell pm disable --user 0 "$package"
    [ $? -eq 0 ] || adbc shell pm disable-user --user 0 "$package"
    if [ $? -ne 0 ]; then 
      read -p "\"$package\" cannot be disabled. Try to uninstall it? [S/n] " confirm
      [[ "$confirm" == "N" || "$confirm" == "n" ]] && continue

      adbc shell pm uninstall -k --user 0 "$package"
    fi

    if [ $? -ne 0 ]; then
      echo "error!"
    fi

  done

fi

}


init_checks
select_packages
disable_packages



