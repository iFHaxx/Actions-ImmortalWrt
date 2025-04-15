#!/bin/bash

function checkEnv() {
    if ! type sysupgrade >/dev/null 2>&1; then
        writeLog 'Your firmware does not contain sysupgrade and does not support automatic updates'
        exit
    fi
}

function writeLog() {
    now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'
    echo ${now_time} $1 | tee -a '/tmp/easyupdatemain.log'
}

function shellHelp() {
    checkEnv
    cat <<EOF
Your firmware already includes Sysupgrade and supports automatic updates
Parameters:
    -c                     Get the cloud firmware version
    -d                     Download cloud Firmware
    -f filename            Flash firmware
    -u                     One-click firmware update
EOF
}

function getCloudVer() {
    checkEnv
    github=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_GITHUB='\(\S*\)'/\1/p")
    github=(${github//// })
    curl "https://api.github.com/repos/${github[2]}/${github[3]}/releases/latest" | jsonfilter -e '@.tag_name' | sed -e 's/.*\([0-9]\{12\}.*\)/\1/'
}

function downCloudVer() {
    checkEnv
    writeLog 'Get github project address'
    github=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_GITHUB='\(\S*\)'/\1/p")
    writeLog "Github project address: $github"
    github=(${github//// })
    writeLog 'Check whether EFI firmware is available'
    if [ -d "/sys/firmware/efi/" ]; then
        suffix="combined-efi.img.gz"
    else
        suffix="combined.img.gz"
    fi
    writeLog "Whether EFI firmware is available: $suffix"
    writeLog 'Get the cloud firmware link'
    url=$(curl "https://api.github.com/repos/${github[2]}/${github[3]}/releases/latest" | jsonfilter -e '@.assets[*].browser_download_url' | sed -n "/$suffix/p")
    writeLog "Cloud firmware link: $url"
    mirror=''
    writeLog "Use mirror URL: $mirror"
    fileName=(${url//// })
    curl -o "/tmp/${fileName[7]}-sha256" -L "$mirror${url/${fileName[7]}/sha256sums}"
    curl -m 10000 -o "/tmp/${fileName[7]}" -L "$mirror$url" >/tmp/easyupdate.log 2>&1 &
    writeLog 'Start downloading firmware, log output in /tmp/easyupdate.log'
}

function flashFirmware() {
    checkEnv
    if [[ -z "$file" ]]; then
        writeLog 'Please specify the file name'
    else
        writeLog 'Get whether to save the configuration'
        writeLog "Whether to save the configuration: $res"
        writeLog 'Start flash firmware, log output in /tmp/easyupdate.log'
        sysupgrade /tmp/$file >/tmp/easyupdate.log 2>&1 &
    fi
}

function checkSha() {
    if [[ -z "$file" ]]; then
        for filename in $(ls /tmp)
        do
            if [[ "${filename#*.}" = "img.gz" && "${filename}" == *"-combined"* ]]; then
                file=$filename
            fi
        done
    fi
    cd /tmp && sha256sum -c <(grep $file $file-sha256)
}

function updateCloud() {
    checkEnv
    writeLog 'Get the local firmware version'
    lFirVer=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_VERSIONS='.*\([0-9]\{12\}\).*'/\1/p")
    writeLog "Local firmware version: $lFirVer"
    writeLog 'Get the cloud firmware version'
    cFirVer=$(getCloudVer)
    writeLog "Cloud firmware version: $cFirVer"
    lFirVer=$(date -d "${lFirVer:0:4}-${lFirVer:4:2}-${lFirVer:6:2} ${lFirVer:8:2}:${lFirVer:10:2}" +%s)
    cFirVer=$(date -d "${cFirVer:0:4}-${cFirVer:4:2}-${cFirVer:6:2} ${cFirVer:8:2}:${cFirVer:10:2}" +%s)
    if [ $cFirVer -gt $lFirVer ]; then
        writeLog 'Need to be updated'
        checkShaRet=$(checkSha)
        if [[ $checkShaRet =~ 'OK' ]]; then
            writeLog 'Check completes'
            file=${checkShaRet:0:-4}
            flashFirmware
        else
            downCloudVer
            i=0
            while [ $i -le 100 ]; do
                log=$(cat /tmp/easyupdate.log)
                str='transfer closed'
                if [[ $log =~ $str ]]; then
                    writeLog 'Download error'
                    i=101
                    break
                else
                    str='Could not resolve host'
                    if [[ $log =~ $str ]]; then
                        writeLog 'Download error'
                        i=101
                        break
                    else
                        str='100\s.+M\s+100.+--:--:--'
                        if [[ $log =~ $str ]]; then
                            writeLog 'Download completes'
                            i=100
                            break
                        else
                            echo $log | sed -n '$p'
                            if [[ $i -eq 99 ]]; then
                                writeLog 'Download timeout'
                                break
                            fi
                        fi
                    fi
                fi
                let i++
                sleep 3
            done
            if [[ $i -eq 100 ]]; then
                writeLog 'Prepare flash firmware'
                checkShaRet=$(checkSha)
                if [[ $checkShaRet =~ 'OK' ]]; then
                    writeLog 'Check completes'
                    file=${checkShaRet:0:-4}
                    flashFirmware
                else
                    writeLog 'Check error'
                fi
            fi
        fi
    else
        writeLog "Is the latest"
    fi
}

if [[ -z "$1" ]]; then
    shellHelp
else
    case $1 in
    -c)
        getCloudVer
        ;;
    -d)
        downCloudVer
        ;;
    -f)
        file=$2
        flashFirmware
        ;;
    -k)
        file=$2
        checkSha
        ;;
    -u)
        updateCloud
        ;;
    *)
        shellHelp
        ;;
    esac
fi
