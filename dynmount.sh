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

    if [ "$(getprop ro.build.version.sdk)" -ge 30 ]; then
       # Android 11 already has data isolation
       exit 1
    fi

    exit 0

    #exit 0 # allow script to run in EnterMntNs stage
    exit 1 # close script and don't allow script to run in EnterMntNs stage
}

res_mount(){
    mount --bind "/mnt/$1" "$1"
}

magisk_cl(){
    magisk --clone-attr "/mnt/$1" "$1"
}

EnterMntNs(){

    # script run after enter the mount name space of app process and you allow this script to run in EnterMntNs stage
    USERID="$(($UID/100000))"
    PKGS="$(pm list package -U | grep "uid:$UID" | awk '{ print $1 }' | sed "s/^package://g")"

    mount -t tmpfs tmpfs /data/data
    mount -t tmpfs tmpfs /data/user
    mount -t tmpfs tmpfs /data/user_de

    mount -t tmpfs tmpfs /data/misc/profiles/cur
    mount -t tmpfs tmpfs /data/misc/profiles/ref


    mkdir -p "/data/data/com.google.android.gms"
    mkdir -p "/data/user/$USERID/com.google.android.gms"
    mkdir -p "/data/user_de/$USERID/com.google.android.gms"

    mount -t tmpfs tmpfs /mnt
    mkdir -p /mnt/data
    mount --bind /data /mnt/data

    for dir in $(find /data/data /data/user /data/user_de /data/misc/profiles/cur /data/misc/profiles/ref); do
        magisk_cl "$dir"
    done


    for PKG in $PKGS; do

    if [ "$PKG" == "com.google.android.gms" ]; then
        continue
    fi


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
    

    res_mount "/data/data/com.google.android.gms"
    res_mount "/data/user/$USERID/com.google.android.gms"
    res_mount "/data/user_de/$USERID/com.google.android.gms"

    
    umount -l /mnt
}

RUN_SCRIPT


