#!/usr/bin/env bash

function help() {
  echo """${0##*./} - Create's an encrypted image
options:
  -s IMG SIZE
  Description: Desired size of the immage
  Default: 1GB

  - i IMG_NAME
  Description: String used to name the image
  Default: vault.img

  -n NODE NAME
  Description: Desired device node name
  Default: enc_dev1
  """
  exit 0
}


if [ "$EUID" -ne 0 ]
  then echo "This script needs privileged access to your environment. Please re-run as sudo or root."
  exit -1
fi

while getopts "hs:n:i:" options; do
    case ${options} in
      n)
        DEVICE_NODE=${OPTARG}
      ;;
      s)
        IMG_SIZE=${OPTARG}
      ;;
      i)
        IMG_NAME=${OPTARG}
      ;;
      :)
        echo -e "Error: -${OPTARG} requires an argument.\n"
        help
      ;;
      *)
        help
      ;;
      \?)
        echo -e "Invalid option: -${OPTARG}\n"
      ;;
    esac
done
shift $((OPTIND -1))

if [ -z "${DEVICE_NODE}" ]; then
  DEVICE_NODE="enc_dev1"
fi

if [ -z "${IMG_SIZE}" ]; then
  IMG_SIZE="1G"
fi

if [ -z "${IMG_NAME}" ]; then
  IMG_NAME="vault.img"
fi

if [ -f "${IMG_NAME}" ]; then
  echo -e "Previous version on ${IMG_NAME} was found on this system. Would you like to recreate the vault or bail?"
  read -p 'Type "YES" to remove or anything else to exit: ' cont
  if [[ "${cont}" == "YES" ]]; then
    rm -f ${IMG_NAME}
  else
    exit 0
  fi
fi

echo "Building binary image of ${IMG_SIZE} size"
dd if=/dev/random of=${IMG_NAME} bs=1 count=0 seek=${IMG_SIZE} || ( echo "Failed to create base image ${IMG_NAME}"; exit -1 )
echo "Creating partition structure"
parted ${IMG_NAME} mklabel gpt mkpart primary 0% 100% || ( echo "Failed to create partitions within image ${IMG_NAME}"; exit -1)
echo "Creating encrypted vault, please enter the desired password once prompted."
cryptsetup luksFormat -M luks2 --pbkdf argon2id -i 5000 ${IMG_NAME} || ( echo "Failed to build encrypted LUKS layer."; exit -1 )
echo "Encrypted vault ${IMG_NAME} was created successfully."