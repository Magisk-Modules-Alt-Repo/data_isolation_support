MODDIR="${0%/*}"

# API_VERSION = 1
STAGE="$1" # prepareEnterMntNs or EnterMntNs
PID="$2" # PID of app process
UID="$3" # UID of app process
PROC="$4" # Process name. Example: com.google.android.gms.unstable
USERID="$5" # USER ID of app
# API_VERSION = 2
# Enable ash standalone
# Enviroment variables: MAGISKTMP, API_VERSION


APP_ID="$(($UID%100000))"

RUN_SCRIPT(){
    if [ "$STAGE" == "prepareEnterMntNs" ]; then
        prepareEnterMntNs
    elif [ "$STAGE" == "EnterMntNs" ]; then
        EnterMntNs
    fi
}

prepareEnterMntNs(){
    # script run before enter the mount name space of app process

    if [ "$API_VERSION" -lt 2 ]; then
        # Need API 2 and newer
        exit 1
    fi


    # Android 11 already has data isolation
    if [ "$(getprop ro.build.version.sdk)" -ge 30 ]; then
       exit 1
    fi

    # Ignore system apps with UID < 10000
    if [ "$APP_ID" -lt 10000 ]; then
        exit 1
    fi

    exit 0

}

res_mount(){
    mount --bind "/mnt/$1" "$1"
}

magisk_cl(){
    magisk --clone-attr "/mnt/$1" "$1"
}

EnterMntNs(){

    # script run after enter the mount name space of app process and you allow this script to run in EnterMntNs stage

    # USERID given by am_proc_start is unrealiable, so we parse USERID from UID
    USERID="$(($UID/100000))"

    # ignore privapp
    if cat /data/system/packages.list | awk '{ if ($2 == '"$APP_ID"') print $5 }' | grep -q "privapp"; then
        exit 1
    fi
    PKGS="$(cat /data/system/packages.list | awk '{ if ($2 == '"$APP_ID"' || $1 == "com.google.android.gms") print $1 }')"

   
    # mount tmpfs layer
    mount -t tmpfs tmpfs /data/data
    mount -t tmpfs tmpfs /data/user
    mount -t tmpfs tmpfs /data/user_de

    mount -t tmpfs tmpfs /data/misc/profiles/cur
    mount -t tmpfs tmpfs /data/misc/profiles/ref

    mkdir -p "/data/user/$USERID"
    mkdir -p "/data/user_de/$USERID"

    mount -t tmpfs tmpfs /mnt
    mkdir -p /mnt/data
    mount --bind /data /mnt/data

    for dir in $(find /data/data /data/user /data/user_de /data/misc/profiles/cur /data/misc/profiles/ref); do
        magisk_cl "$dir"
    done

    if [ "$APP_ID" -ge 90000 ] && [ "$APP_ID" -le 99999 ]; then
        umount -l /mnt
        exit 0
    fi

    for PKG in $PKGS; do

    # bind mount its own folder

    mkdir -p "/data/data/$PKG"
    mkdir -p "/data/user/$USERID/$PKG"
    mkdir -p "/data/user_de/$USERID/$PKG"

    res_mount "/data/data/$PKG"
    res_mount "/data/user/$USERID/$PKG"
    res_mount "/data/user_de/$USERID/$PKG"

    mkdir -p "/data/misc/profiles/cur/$USERID/$PKG"
    mkdir -p "/data/misc/profiles/ref/$PKG"

    res_mount "/data/misc/profiles/cur/$USERID/$PKG"
    res_mount "/data/misc/profiles/ref/$PKG"

    done

    
    umount -l /mnt
}

RUN_SCRIPT


