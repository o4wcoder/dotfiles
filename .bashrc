#echo "drink beer"

# Change BASH prompt
PS1=`hostname`':$PWD> ';

# Set default Language to override default UTF-8 setting
export LANG=en_US

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
# Used for Git Repo/builds
#source /opt/rh/python27/enable
#source /opt/rh/git19/enable
#source yocto/oe-init-build-env

alias syocto1='ssh chare@yocto-build01-atl'
alias syocto2='ssh chare@yocto-build02-atl' 
alias syocto3='ssh chare@yocto-build03-atl'
alias syocto4='ssh chare@yocto-build04-atl'
alias syocto5='ssh chare@yocto-build05-atl'

alias wchare='cd /opt/workspaces/chare'
#alias setscripts='source /opt/gitatomtools/atomfunctions.sh'
alias wscripts='cd /opt/gitatomtools/'
function gpush
{
    #git checkout -b master
    #git remote add origin $1
    git push -u origin master
}

function bld_mta 
{
   genconf ../defconfig/gw_ncs.config
   bitbake virtual/core-image-gateway
}


function bld_doc
{
   genconf ../rdk5.5_dgwsdk_1682_ct.config
   bitbake virtual/core-image-gateway

}
 
source ~wintersd/arrisfunctions.sh
#source /opt/gitatomtools/atomfunctions.sh
source /opt/gitatomtools/yoctosetup.sh
# create aliases
alias   ct='cleartool'
alias   h='history'
alias   ng='newgrp ccase'
alias   gdoc='cd /vobs/TS_nextgen'

# Change dir back to your base snapshot directory
# Usage: base
function base
{
    if [ -d $BASEVIEW/TS_nextgen ]; then
       cd $BASEVIEW/TS_nextgen
    else
       cd $BASEVIEW
    fi
}

# Create BASH function
#alias  mkview='cleartool mkview -tag \!* -stgloc -auto'
function mkview
{
    cleartool mkview -tag $1 -stgloc -auto
}
function sv()
{
    cleartool setview $1
    ct mount /vobs/TS_nextgen
}

function diffg
{
   ct diff -pre -g $1
}

function cleansnap
{
    cd $BASEVIEW
    cd ..
    cd ..
    TEMP=`pwd`
    cd $BASEVIEW
    perl $TEMP/vobs/ppm3_tools/scripts/snap_priv_clean.pl
}

function makedir
{
    find . -follow -type f -exec cleartool mkelem -nc '{}' \;
}

function lsci
{
   view=`pwd | awk -F / '/sview/{print $3}'`
   checkouts=`lsco`
   for item in $checkouts
   do
      latest_ver=`cleartool describe -s $item | sed 's#CHECKEDOUT#LATEST#g'`
      latest_ver_num=`cleartool describe -s $latest_ver | sed 's#.*/\([0123456789]*\)$#\1#'`
      let latest_ver_num++
      check_in_ver=`cleartool describe -s $item | sed 's#CHECKEDOUT#'${latest_ver_num}'#g'`
      if [ -n "$view" ]
      then
         check_in_ver=`echo $check_in_ver | sed 's#/sview/'$view'##g'`
      fi
      echo $check_in_ver
   done
}

# Find a pattern in a set of [all] files and subdirectories.
function findall()
{
   grep -rnw . -e $1 
}

# Find a pattern in a set of Makefiles and subdirectories.
function findmake()
{ 
   find . -follow -name "Makefile" -o -name "*mk" -o -name "*mak" -o -name "*make" -o -name "*vendor" -exec grep -i -n "$1" '{}' \; -print ; 
}

function findm()
{ find . -follow -name "Makefile" -exec grep -i -n "$1" '{}' \; -print ; }

# Check in all changes in a view with the comments provided in the file .../TS_nextgen/comment
# Usage: cichanges
function fciall
{
    cleartool lsco -cview -avobs -short | xargs -i -t cleartool ci -cfile ci.txt -ide {}
    echo Relisting checkouts in case something did not get checked in...........
    cleartool lsco -cview -avobs -short
}

# Change BASH prompt
PS1=`hostname`':$PWD> ';

alias d='ls'
alias D='ls -al'
alias myco='ct lsco -me -cview -avob -short 2> /dev/null'
alias findco='cleartool lsco -cview -avobs -short'
alias up='cd ..'
alias images='cd $BASEVIEW/build/dsdk/images'
alias vimages='cd $BASEVIEW/build/vsdk/images'
alias vgimages='cd build/vgwsdk/images'
alias dgimages='cd $BASEVIEW/build/dgwsdk/images'
alias dg='cd build/dgwsdk/images'
alias vg='cd build/vgwsdk/images'
alias loads='cd $BASEVIEW/load_store'
alias tftp='ftp 10.2.121.108'
alias libs='cd $BASEVIEW/ti/arris_libs/src'
alias web='cd $BASEVIEW/ti/arris_docsis/src/web'
alias vmweb='cd $BASEVIEW/ti/arris_docsis/src/vmweb'
alias snmp='cd $BASEVIEW/ti/docsis/src/common/management/snmp/src'
alias snmpd='cd /vobs/TS_nextgen/ti/docsis/src/common/management/snmp/src'
alias psnmp='cd $BASEVIEW/ti/pacm/src/snmp/src'
alias psnmpd='cd /vobs/TS_nextgen/ti/pacm/src/snmp/src'
alias pevent='cd $BASEVIEW/ti/pacm/src/services/src/event_manager'
alias event='cd $BASEVIEW/ti/docsis/src/common/management/event_manager'
alias cevent='cd $BASEVIEW/ti/common_components/src/event_mngr/src/event_mgr/src'
alias sercomm='cd $BASEVIEW/../ti_thirdparty/thirdparty/sercomm'
alias sercommd='cd /vobs/ti_thirdparty/thirdparty/sercomm'
alias mibs='cd $BASEVIEW/../ARRIS_MIBS'
alias mibsd='cd /vobs/ARRIS_MIBS'
alias gwsnmp='cd $BASEVIEW/ti/gw/src/vendor/src/arris_gwsnmp'
alias gui='cd $BASEVIEW/../ARRIS_GUI'
alias guid='cd /vobs/ARRIS_GUI'
alias vmgui='cd $BASEVIEW/../ARRIS_GUI/GW/VIRGIN_MEDIA'
alias vmguid='cd /vobs/ARRIS_GUI/GW/VIRGIN_MEDIA'
alias scripts='cd $BASEVIEW/../ppm3_tools/scripts'
alias scriptsd='cd /vobs/ppm3_tools/scripts'
alias init='cd $BASEVIEW/ti/arris_docsis/src/init_sercomm'
alias initd='cd $BASEVIEW/ti/arris_docsis/src/init_sercomm'
alias fci='ct ci -cfile ci.txt'
alias based='cd /vobs/TS_nextgen'
alias buildtw='bld_d30 vsdk tg852 tw'
alias buildct='bld_d30 vsdk tg852 ct'
alias build='bld_d30 vsdk tg852'
alias buck='ssh buckeye'
alias buzz='ssh buzz'
alias panda='ssh 192.168.89.212'

alias protect='perl /view/ccbuild_tools/vobs/ppm3_tools/scripts/ctprotect.pl'
umask 022
export DISPLAY=10.2.21.189:0

export PATH=/usr/atria/bin:/usr/atria/etc:/usr/local/buildtools/ti-puma5_2010/ti-puma5/usr/bin:/view/ccbuild_tools/vobs/ppm3_tools/scripts/:/sbin:/opt/rh/git19/root/usr/bin/git:/home/sw/chare/bin:/opt/rh/python27/root/usr/lib64/:$PATH

#export PATH=/usr/atria/bin:/usr/atria/etc:/usr/local/buildtools/ti-puma5/usr/bin/:/view/ccbuild_tools/vobs/ppm3_tools/scripts/:$PATH

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL`ct pwv -s`$GREEN ]\$ $NORMAL \e]2;`ct pwv -s` -- \u@\H -- \w \a"
  PS1="[\u@\h \W]\\$ "
fi

export LC_CTYPE=C

# OCG build env set start

# Intel SDK Toolchain for Arm and Atom
#export ORIGINAL_PATH=$PATH
#export INTEL_PUMA_TOOLCHAIN_INSTALL_DIR=/home/sw/mcummings/CT_OCG/PumaSDK/ARM/NewToolChain && unset PATH && export PATH=$INTEL_PUMA_TOOLCHAIN_INSTALL_DIR/usr/bin:$ORIGINAL_PATH

# OCG Buildtools from svn checkout
#export PATH=$PATH:/home/sw/mcummings/CT_OCG/ocgbuildtools
# OCG build env set end

# End /etc/bashrc
