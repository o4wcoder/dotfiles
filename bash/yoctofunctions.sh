#!/bin/sh
# Lruby - 7/31/2015 - removed pulling the meta-arrisrdkb layer as we decided not to use it
##############################################################
#                    Global Defs                             #
##############################################################
HEADER_BZIMAGE_M16XX='0x1 0x10a 0x7E81FF 0x51 1 0 1 2 1 0 0 1'
HEADER_ROOTFS_M16XX='0x1 0x10a 0x7E81FF 0x52 1 0 2 2 1 0 0 0'
HEADER_BZIMAGE_M1682V1='0x1 0x10c 0x7E81FF 0x71 1 0 1 2 1 0 0 1'
HEADER_ROOTFS_M1682V1='0x1 0x10c 0x7E81FF 0x72 1 0 2 2 1 0 0 0'
HEADER_BZIMAGE_M1682='0x1 0x10e 0x27E81FF 0x91 1 0 1 2 1 0 0 1'
HEADER_ROOTFS_M1682='0x1 0x10e 0x27E81FF 0x92 1 0 2 2 1 0 0 0'
HEADER_BZIMAGE_M24MG='0x1 0x10b 0x7E81FF 0x61 1 0 1 2 1 0 0 1'
HEADER_ROOTFS_M24MG='0x1 0x10b 0x7E81FF 0x62 1 0 2 2 1 0 0 0'
HEADER_BZIMAGE_M24TG='0x1 0x10f 0x7E81FF 0xa1 1 0 1 2 1 0 0 1'
HEADER_ROOTFS_M24TG='0x1 0x10f 0x7E81FF 0xa2 1 0 2 2 1 0 0 0'

ARM_HEADER_GW_M1682='0x1 0x10e 0xf67E81FF 0x90 1 0 1 1 1 0 0 0'
ARM_HEADER_GW_M1682_WITH_ATOM='0x1 0x10e 0xf67E81FF 0x90 1 0 1 1 1 0 0 1'
ARM_HEADER_BZIMAGE_M1682='0x1 0x10e 0xf67E81FF 0x0 0 0 1 1 0 0 1 1'   

export LIST_ARRIS_COMP="wpsgpio, cli, bootparams, sppedtest, nuttcp, hot, factory, rpc, qca-rpc-wlan-config rpc"

# Latest Intel drop branch
INTEL_DROP_BRANCH="intel_arm_drop_r5.5.0.5_er2"

set_repo_env()
{
   git config --global --unset apply.ignorewhitespace 
   git config --global apply.whitespace fix
   git config --global core.autocrlf input

   #Clean up PATH
   export PATH="`echo ${PATH} | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"
}

mkrepo_arm_internal()
{
   # Verify we have the required passed in parameters
   #check_function_parms $1 $2
   if [ "$2" = "ct" ] ; then
      export ARRIS_BRANCH="friendly3_ct"
   elif [ "$2" = "intel" ] ; then
      export ARRIS_BRANCH="$INTEL_DROP_BRANCH"
   elif [ "$2" = "int" ] ; then
      export ARRIS_BRANCH="arm_int"
   elif [ "$2" = "int_ct" ] ; then
      export ARRIS_BRANCH="arm_int_ct"
   elif [ "$2" = "int_merge_10192015" ] ; then
      export ARRIS_BRANCH="arm_int_merge_10192015"
   else
      export ARRIS_BRANCH="arm_dev"
   fi
  
   echo "Setting up ARM workspace on branch $ARRIS_BRANCH"

   #Get branch if one is supplied
   if [ "$1" = "puma6" ] ; then
     #INTEL_BRANCH="r5.0-er4"
     PLATFORM_VER="PUMA6"
   elif [ "$1" = "puma7" ] ; then
     #INTEL_BRANCH="r5.0-rc4"
     PLATFORM_VER="PUMA7"
   fi

   CODETRAIN=$2
   shift
   shift

   set_repo_env

   WORKINGENV_FILE="WORKINGENV"

   #Get workspace path and save it
   WORKSPACE_PATH=$(pwd)
   WORKSPACE_TYPE="ARM"
   echo "export WORKSPACE_PATH=$WORKSPACE_PATH" > $WORKINGENV_FILE
   echo "export ARRIS_BRANCH=$ARRIS_BRANCH" >> $WORKINGENV_FILE
   echo "export WORKSPACE_TYPE=$WORKSPACE_TYPE" >> $WORKINGENV_FILE
   echo "export PLATFORM=$PLATFORM_VER" >> $WORKINGENV_FILE
   BUILD_CONF_PATH="$WORKSPACE_PATH/build/conf/local.conf"


   #Pull ARRIS/Intel Source Code
   #Pulling only the RDK-B version of the source for now
   echo "Checking codetrain $CODETRAIN"
   if [ "$CODETRAIN" = "ct" ] || [ "$CODETRAIN" = "intel" ] || [ "$CODETRAIN" = "int_ct" ] ; then
      echo "Pulling Intel ARM Source..."
      git clone git@ttmgit.arrisi.com:TTM/intel-arm-src.git -b $ARRIS_BRANCH
   else
      if [ "$CODETRAIN" = "int" ] ; then
         echo "Pulling ARRIS ARM RDK-B Source..."
         git clone git@ttmgit.arrisi.com:TTM/arris-arm-src.git -b arm_int_rdk-b 
      elif [ "$CODETRAIN" = "int_merge_10192015" ] ; then
         echo "Pulling ARRIS ARM RDK-B Source..."
         git clone git@ttmgit.arrisi.com:TTM/arris-arm-src.git -b arm_int_rdk-b_merge_10192015
      else
         echo "Pulling ARRIS ARM Source..."
         git clone git@ttmgit.arrisi.com:TTM/arris-arm-src.git -b arm_dev_rdk-b 
      fi
   fi

   git clone git@ttmgit.arrisi.com:TTM/arm-yocto-setup.git -b $ARRIS_BRANCH
   mv arm-yocto-setup/** .
   mv arm-yocto-setup/.git .
   mv arm-yocto-setup/.gitignore .

   rm -rf arm-yocto-setup 

   . $WORKSPACE_PATH/arm_yocto_setup -intelce $ARRIS_BRANCH

   ####################################
   # Set default values to local.conf #
   ####################################

   # Setup path to Intel source code
   if [ "$CODETRAIN" = "ct" ] || [ "$CODETRAIN" = "intel" ] || [ "$CODETRAIN" = "int_ct" ] ; then
      sed -i "s|INTELSDKPATH =.*|INTELSDKPATH = \"$WORKSPACE_PATH/intel-arm-src\"|g" $BUILD_CONF_PATH
   else
      sed -i "s|INTELSDKPATH =.*|INTELSDKPATH = \"$WORKSPACE_PATH/arris-arm-src/TS_nextgen\"|g" $BUILD_CONF_PATH
   fi

   # Set path to ARM binaries
   sed -i "s|INTEL_BINARY_GIT =.*|INTEL_BINARY_GIT = \"git://git@ttmgit.arrisi.com/TTM/arm-src-binaries.git;protocol=ssh;branch=$ARRIS_BRANCH\"|g" $BUILD_CONF_PATH

}

mkrepo_atom_internal()
{
  # Verify we have the required passed in parameters
  check_function_parms $1 $2
  if [ $? != 0 ]
  then
     return 1
  fi
   

   #Get branch if one is supplied
   if [ "$1" = "puma6" ] ; then
     #INTEL_BRANCH="r5.0-er4"
     INTEL_BRANCH="r6.0-er2"
     #INTEL_BRANCH="r5.5-er1"
     PLATFORM_VER="PUMA6"
   elif [ "$1" = "puma7" ] ; then 
     INTEL_BRANCH="cgm_sw_r1.0er8"  
     PLATFORM_VER="PUMA7"
   fi

   CODETRAIN=$2
   
   set_arris_repo_vars $1 $2 

   if [ $? != 0 ]  
   then 
       echo "ERROR in set_arris_repo_vars"
       return 1
   fi 

   #clean out input params
   shift
   shift 

   set_repo_env

   WORKINGENV_FILE="WORKINGENV"

   #Get workspace path and save it
   WORKSPACE_PATH=$(pwd)
   WORKSPACE_TYPE="ATOM"
   echo "export WORKSPACE_PATH=$WORKSPACE_PATH" > $WORKINGENV_FILE
   echo "export ARRIS_GIT=$ARRIS_GIT" >> $WORKINGENV_FILE
   echo "export ARRIS_BRANCH=$ARRIS_BRANCH" >> $WORKINGENV_FILE
   echo "export WORKSPACE_TYPE=$WORKSPACE_TYPE" >> $WORKINGENV_FILE
   echo "export PLATFORM=$PLATFORM_VER" >> $WORKINGENV_FILE 
   INTEL_META_PATH="file://$WORKSPACE_PATH/intel_atom_repos/intelcerel-meta"
   BUILD_CONF_PATH="$WORKSPACE_PATH/build/conf/local.conf"

   echo "Pulling $PLATFORM_VER intel source repos from branch $INTEL_BRANCH..."
  
   # Pull all repos from GitLab
   git clone git@ttmgit.arrisi.com:TTM/intel_atom_repos.git -b $INTEL_BRANCH
   echo "Pulling yocto repos..."

   git clone intel_atom_repos/intelcerel-yocto-build -b $INTEL_BRANCH

   echo "Pulling out Yocto 1.6 repo"
   source intelcerel-yocto-build/intelce-setup-yocto-build -y 1.6 -u $INTEL_META_PATH -b $INTEL_BRANCH

   if [ "$PLATFORM_VER" = "PUMA7" ] ; then
     echo "Pulling out PUMA7 cougar mountain repos"

     #cd yocto
     #git clone ../intel_atom_repos/intelcerel-meta-cougarmountain.git
     #mv intelcerel-meta-cougarmountain meta-cougarmountain     
     #cd ..
     git clone intel_atom_repos/intelcerel-meta-cougarmountain.git yocto/meta-cougarmountain -b $INTEL_BRANCH

     # Pull down ARRIS ATOM Source
     echo "Pulling ARRIS ATOM Source..."
     git clone git@ttmgit.arrisi.com:TTM/arris-atom-src.git -b $ARRIS_BRANCH
     
   fi

   echo "Pulling ARRIS repo..."
   git clone git@ttmgit.arrisi.com:TTM/meta-arrisgw.git -b $ARRIS_BRANCH
   mv meta-arrisgw yocto/

#   We decided not to use this meta layer. Don't pull it anymore
#   if [ "$ARRIS_BRANCH" == "atom_dev_rdk-b" ]
#   then
#       echo "Pulling ARRIS RDK-B repo..."
#       git clone git@ttmgit.arrisi.com:TTM/meta-arrisrdkb.git -b $ARRIS_BRANCH
#       mv meta-arrisrdkb yocto/
#   fi

   # Modify Intel Conf files
   SCM_PATH="INTELCE_SCM_PATH ?= \"git://$WORKSPACE_PATH/intel_atom_repos\""
   INTEL_CONF_FILE="$WORKSPACE_PATH/yocto/meta-intelce/conf/distro/intelce.conf"
   sed -i '/INTELCE_SCM_PATH_pn/d' $INTEL_CONF_FILE
   sed -i "s|INTELCE_SCM_PATH.*|$SCM_PATH|g" $INTEL_CONF_FILE

   if [ "$PLATFORM_VER" = "PUMA7" ] ; then
      INTEL_CGM_CONF_FILE="$WORKSPACE_PATH/yocto/meta-cougarmountain/conf/distro/cougarmountain.conf"
      sed -i '/INTELCE_SCM_PATH_pn/d' $INTEL_CGM_CONF_FILE 
      sed -i '/INTELCE_REPO_PREFIX_pn/d' $INTEL_CGM_CONF_FILE 
   fi 
   #Modify Intel Classes files
   INTEL_CLASSES_FILE="$WORKSPACE_PATH/yocto/meta-intelce/classes/intelce_package.bbclass"
   sed -i "s|INTELCE_SCM_PATH ?.*|$SCM_PATH|g" $INTEL_CLASSES_FILE

   #Set current Intel branch
   INTELCE_SRCREV="INTELCE_SRCREV ?= \"$INTEL_BRANCH\""
   sed -i "s|INTELCE_SRCREV ?.*|$INTELCE_SRCREV|g" $INTEL_CLASSES_FILE
   INTELCE_SRCREV="INTELCE_SRCREV ?= \"$INTEL_BRANCH\""
   sed -i "s|INTELCE_SRCREV ?.*|$INTELCE_SRCREV|g" $INTEL_CONF_FILE

   # Modify repo prefix
   sed -i "s|INTELCE_REPO_PREFIX ?.*|INTELCE_REPO_PREFIX ?= \"intelcerel-\"|g" $INTEL_CLASSES_FILE

   #Modify pkg branch 
   sed -i "s|INTELCE_PKG_BRANCH ?.*|INTELCE_PKG_BRANCH ?= \"$INTEL_BRANCH\"|g" $INTEL_CLASSES_FILE
   sed -i "s|INTELCE_PKG_BRANCH ?.*|INTELCE_PKG_BRANCH ?= \"$INTEL_BRANCH\"|g" $INTEL_CONF_FILE
   #Modify SSH 
   sed -i "s|INTELCE_ENABLE_GIT_SSH ?= \"yes\"|INTELCE_ENABLE_GIT_SSH ?= \"no\"|g" $INTEL_CLASSES_FILE

   # Clean up PATH for local dirs starting with .
   export PATH="`echo ${PATH} | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"


   #Clean up PATH
   export PATH="`echo ${PATH} | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"

   #Setup build environment
   #if [ "$PLATFORM_VER" = "PUMA7" ] ; then
   #   export TEMPLATECONF=$WORKSPACE_PATH/yocto/meta-cougarmountain/conf 
   #else
      export TEMPLATECONF=$WORKSPACE_PATH/yocto/meta-arrisgw/conf
   #fi

   #if [ "$PLATFORM_VER" = "PUMA7" ] ; then
   #   source intelcerel-yocto-build/yocto_build_setup -l meta-cougarmountain
   #else
      source yocto/oe-init-build-env
   #fi

#   set_repoparms_to_localconf 
   set_repoparms_to_env

   ####################################
   # Set default values to local.conf #
   ####################################
   # Setup local open source code in ARRIS layer
   echo "Adding mods to build config..."
   echo "SOURCE_MIRROR_URL ?= \"file:///opt/gitatomtools/thirdparty/intel_open_source\"" >> $BUILD_CONF_PATH

   echo "DEV_OVERRIDE = \"nooverride\"" >> $BUILD_CONF_PATH 

   # Pull down ARRIS ATOM Source
   if [ "$PLATFORM_VER" = "PUMA7" ] ; then
      echo "ARRISSDKPATH = \"$WORKSPACE_PATH/arris-atom-src/\"" >> $BUILD_CONF_PATH
   fi

   #Create folder in workspaces's build directory to put arris source
   mkdir $WORKSPACE_PATH/build/arris_source   
   mkdir $WORKSPACE_PATH/build/arris_source/files

}

set_template()
{ 
   WORKSPACE_PATH=$(pwd)
   export TEMPLATECONF=$WORKSPACE_PATH/yocto/meta-arrisgw/conf
   printenv TEMPLATECONF
}

clean_yocto()
{
   CMD="rm -rf $WORKSPACE_PATH/build/tmp"
   echo $CMD
   $CMD
   
   CMD="rm -rf $WORKSPACE_PATH/build/pkg"
   echo $CMD
   $CMD

   CMD="rm -rf $WORKSPACE_PATH/build/downloads"
   echo $CMD
   $CMD

   CMD="rm -rf $WORKSPACE_PATH/build/cache"
   echo $CMD
   $CMD

   CMD="rm -rf $WORKSPACE_PATH/build/sstate-cache"
   echo $CMD
   $CMD
}

check_repo_changes()
{
   REPO_PATH=$1
   
   if [ ! -z "$2" ] ; then
      BRANCH=$2
   else
      BRANCH=$ARRIS_BRANCH
   fi

   cd $REPO_PATH

   if git diff-index --quiet HEAD -- ; then
     git pull origin $BRANCH 
   else
     echo "Have local chnages in $REPO_PATH. Need to manually do a 'git pull' and merge if necessary."
   fi
   
}

update_yocto()
{
   CUR_PATH=$(pwd)

   #Update arris_tools repo
   check_repo_changes $WORKSPACE_PATH/arris_tools "tools_dev"
   
   source yoctofunctions.sh

   if [ $WORKSPACE_TYPE = "ARM" ] ; then
 
      #Update the base directory arm-yocto-setup-repo
      check_repo_changes $WORKSPACE_PATH/
      #Update meta-intelce-arm repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-intelce-arm

      #Update meta-intelce-arm-bsp repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-intelce-arm-bsp

      #Update meta-intelce-arm-common repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-intelce-arm-common

      #Update meta-intelce-base repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-intelce-base

      #Update meta-arrisgw repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-arrisgw-arm

      if [ -d $WORKSPACE_PATH/yocto/meta-arrisgw-arm-bin ] ; then
         check_repo_changes $WORKSPACE_PATH/yocto/meta-arrisgw-arm-bin
      fi
   elif [ $WORKSPACE_TYPE = "ATOM" ] ; then
      #Update meta-arrisgw repo
      check_repo_changes $WORKSPACE_PATH/yocto/meta-arrisgw 
   fi

   #return to place where command was run
   cd $CUR_PATH 
}

srepo_internal()
{

   if [ -f WORKINGENV ] ; then
      echo "Seting up workspace environment."
      cat WORKINGENV
      source WORKINGENV

   if [ $WORKSPACE_TYPE = "ARM" ] ; then
      #source arm_yocto_setup -intelce $ARRIS_BRANCH
      source yocto_build_setup -l meta-intelce-arm -b build

      echo "Building with ARRIS header for a specific hardware type use 'bld_arm'"
      echo ""
      display_arm_usage
   elif [ $WORKSPACE_TYPE = "ATOM" ] ; then
      if [ $PLATFORM = "PUMA6" ] ; then
         export TEMPLATECONF=$WORKSPACE_PATH/yocto/meta-arrisgw/conf
         source yocto/oe-init-build-env
      elif [ $PLATFORM = "PUMA7" ] ; then
         source intelcerel-yocto-build/yocto_build_setup -l meta-cougarmountain
      fi
      export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE WORKSPACE_PATH ARRIS_GIT ARRIS_BRANCH DEV_OVERRIDE"
   fi
   else
      echo "Could not find WORKINGENV file. Not a valid workspace."
   fi
   
}

display_usage()
{
   echo "Usage: bld_atom <platform> <hardware type>"
   echo "Supported platforms: puma6, puma7"
   echo "Supported HW variants: 16xx, 1682v1, 1682, mg24xx, tg24xx"

}

display_arm_usage()
{
   echo "Usage: bld_arm [options] <platform> <sdk> <mta> <cet> <hardware type>"
   echo "Supported platforms: puma6, puma7"
   echo "Supported sdk: dsdk, vsdk, vgwsdk, dgwsdk"
   echo "Supported mta: pc20"
   echo "Supported cert: mac14, bpi23"
   echo "Supported HW variants: 16xx, 1682v1, 1682, mg24xx, tg24xx"
   echo "OPTIONS"
   echo "  -sw-ver <version>"
   echo "     where <version> should be specified as mm.pp.bb"
   echo "     and mm is the minor version"
   echo "         pp is the patch version"
   echo "         bb is the build version"
}

check_hw_type()
{
#    echo "In check_hw_type with par $1"
    if [ "$1" = "16xx" ] ; then
        IS_HW_VALID=true
    elif [ "$1" = "1682v1" ] ; then
        IS_HW_VALID=true
    elif [ "$1" = "1682" ] ; then
        IS_HW_VALID=true
    elif [ "$1" = "mg24xx" ] ; then
        IS_HW_VALID=true
    elif [ "$1" = "tg24xx" ] ; then
        IS_HW_VALID=true
    else
        IS_HW_VALID=false
    fi
}

check_sdk()
{
   if [ "$1" = "dsdk" ] ; then
       IS_SDK_VALID=true
   elif [ "$1" = "vsdk" ] ; then
       IS_SDK_VALID=true
   elif [ "$1" = "dgwsdk" ] ; then
       IS_SDK_VALID=true
   elif [ "$1" = "vgwsdk" ] ; then
       IS_SDK_VALID=true
   else
       IS_SDK_VALID=false
   fi
}

check_platform()
{
    if [ "$1" = "puma6" ] ; then
       IS_PLATFORM_VALID=true
    elif [ "$1" = "puma7" ] ; then
       IS_PLATFORM_VALID=true
    else
       IS_PLATFORM_VALID=false
    fi
}

# Check option parameter agains array list of build args
findOptionMatch()
{
    opt=$1
    shift
    array=("${@}")

    for j in "${array[@]}"
    do
       if [ $j = "$opt" ] ; then
          FOUND_MATCH=true
          return 0
       fi
    done

    FOUND_MATCH=false
}

bld_arm()
{
    SW_VERSION="10.0.X"    # default software version -- to use if not specified
    FW_PRENAME=TS
    FW_POSTNAME=_MMDDYY_ARRIS_
    FW_BLDEXT=
    FW_CERT=
    if [ ! $(pwd) = "$WORKSPACE_PATH/build" ] ;then
       echo "You must be in the build directory to start a build"
       return
    fi

    args_array=("${@}")

    platformOptions=( puma6 puma7 )
    sdkOptions=( dsdk dgwsdk vsdk vgwsdk )
    hwOptions=( 16xx 1682v1 1682 mg24xx tg24xx )
    mtaOptions=( pc20 )
    certOptions=( bpi23 mac14)
    # The following are switches that expect a parameter to follow
    switchOptionsWithParm=( -sw-ver )
    # flagOptions are simple flag options (command switches) which
    # should not be followed by a parameter.
    flagOptions=(  )

    n=1   # array indexer is referenced to 1 (nth element in array)
    SW_IN_USE=
    for i in "${args_array[@]}"
    do
        # Handle parameters to switches that require one.
        # All elements of array switchOptionsWithParm need to be handled in
        # the case statement.
        if [ -n "${SW_IN_USE}" ] ; then
            case $SW_IN_USE in
            # note that the leading dash was already removed
                sw-ver)
                    SW_VERSION="$i"
                    ;;
                *)
                    ;;
            esac
            SW_IN_USE=
        fi

        # Handle command switches which take a parameter
        findOptionMatch "$i" "${switchOptionsWithParm[@]}"
        if [ "$FOUND_MATCH" = "true" ] ; then
            # Guard against the user not passing enough args on the command line,
            # since these switches expect a parameter to follow.
            if [ $n -ge ${#args_array[@]} ] ; then
                echo "ERROR: Switch ${i} expects a parameter to follow"
                display_arm_usage
                return
            fi
            SW_IN_USE=${i#?}   # (leading dash removed)
            continue
        fi
        findOptionMatch "$i" "${platformOptions[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            PLATFORM=$i

        fi

        findOptionMatch "$i" "${sdkOptions[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            SDK=$i
        fi

        findOptionMatch "$i" "${hwOptions[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            HW=$i
            export HW_REV="$HW"
            if [[ ! "$BB_ENV_EXTRAWHITE" =~ /HW_REV/ ]] ; then
                export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE HW_REV"
            fi
        fi

        findOptionMatch "$i" "${mtaOptions[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            MTA=$i
        fi

        findOptionMatch "$i" "${certOptions[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            CERT=$i
            FW_CERT=".${CERT^^}"
        fi

        # Handle optional flags
        findOptionMatch "$i" "${flagOptions=[@]}"
        if [ $FOUND_MATCH = "true" ] ; then
            i=${i#?}   # (leading dash removed)
            # Add strings from flagOptions array (less the dash) as cases below:
            case "$i" in
                *)
                    echo "ERROR: unsupported flag (-${i})"
                    return
                ;;
            esac
        fi
    done

    case "$PLATFORM" in
        puma6)
            case "$SDK" in
                dsdk)
                    FW_BLDEXT=CM
                ;;
                dgwsdk)
                    echo "Using DGWSDK base config"
                    DEFCONFIG="rdk5.5_dgwsdk_1682_ct.config"
                    FW_BLDEXT=DG
                ;;
                vsdk)
                    FW_BLDEXT=TM
                    case "$MTA" in
                        pc20)
                        ;;
                    esac
                ;;
                vgwsdk)
                    echo "Using VGWSDK base config"
                    DEFCONFIG="rdk5.5_vgwsdk_1682_ct.config"
                    FW_BLDEXT=TG
                    case "$MTA" in
                        pc20)
                        ;;
                    esac

                ;;
                *)
                    echo "Missing SDK type in build command"
                    display_arm_usage
                    return
            esac
    ;;
    puma7)
        echo "PUMA7 not supported yet"
    ;;
    *)
        echo ""
        echo "Missing Platform type in build command"
        display_arm_usage
        return
    esac

    # Remove an existing buildconfig file
    if [ -e $WORKSPACE_PATH/defconfig/buildconfig ] ; then
        rm $WORKSPACE_PATH/defconfig/buildconfig 
    fi
    # Copy base config to buildconfig in case we need to modify it on a per line basis
    cp $WORKSPACE_PATH/defconfig/$DEFCONFIG $WORKSPACE_PATH/defconfig/buildconfig
    #echo "$WORKSPACE_PATH/defconfig/$DEFCONFIG $WORKSPACE_PATH/defconfig/buildconfig"
    BLDCFGFILE="$WORKSPACE_PATH/defconfig/buildconfig"

    case "$CERT" in
        mac14)
            echo "Setting mac14 flag"
            sed -i "s|# CONFIG_TI_DOCSIS_MAC14 is not set|CONFIG_TI_DOCSIS_MAC14=y|g" ${BLDCFGFILE}
        ;;
        bpi23)
            echo "Setting bpi23 flag"
            sed -i "s|# CONFIG_TI_DOCSIS_BPI23 is not set|CONFIG_TI_DOCSIS_BPI23=y|g" ${BLDCFGFILE}
        ;;
        *)
        ;;
    esac

    # Set the software release version information
    SW_VER_MINOR=${SW_VERSION%%.*}
    SW_VER_PATCH=${SW_VERSION#*.}    # temporarily hold string with minor version stripped off
    SW_VER_BLD=${SW_VER_PATCH#*.}    # extract everything past the patch version number
    SW_VER_PATCH=${SW_VER_PATCH%%.*} # now we can reduce to just the patch version
    # Make sure no part of the SW version is undefined
    if [ ${#SW_VER_MINOR} -eq 0 ] || [ ${#SW_VER_PATCH} -eq 0 ] || [ ${#SW_VER_BLD} -eq 0 ] ; then
        echo "Cannot have empty/undefined part (minor, patch, or build) of software version."
        display_arm_usage
        return 1;
    fi
    echo "Setting SW version information in defconfig"
    VNAME=CONFIG_VENDOR_ARRIS_FW_VERSION
    eval "sed -i -r 's|(# ${VNAME} is not set\|${VNAME}=).*|${VNAME}=\"${SW_VERSION}\"|g'" ${BLDCFGFILE}
    VNAME=CONFIG_VENDOR_ARRIS_FW_MINOR
    eval "sed -i -r 's|(# ${VNAME} is not set\|${VNAME}=).*|${VNAME}=\"${SW_VER_MINOR}\"|g'" ${BLDCFGFILE}
    VNAME=CONFIG_VENDOR_ARRIS_FW_PATCH
    eval "sed -i -r 's|(# ${VNAME} is not set\|${VNAME}=).*|${VNAME}=\"${SW_VER_PATCH}\"|g'" ${BLDCFGFILE}
    VNAME=CONFIG_VENDOR_ARRIS_FW_BUILD
    eval "sed -i -r 's|(# ${VNAME} is not set\|${VNAME}=).*|${VNAME}=\"${SW_VER_BLD}\"|g'" ${BLDCFGFILE}
    # Format the software version portion of the firmware name definition
    FW_VER=""
    if [ ${#SW_VER_MINOR} -eq 1 ] ; then
        FW_VER="0${SW_VER_MINOR}"
    else
        FW_VER="${SW_VER_MINOR}"
    fi
    if [ ${#SW_VER_PATCH} -eq 1 ] ; then
        FW_VER="${FW_VER}0${SW_VER_PATCH}"
    else
        FW_VER="${FW_VER}${SW_VER_PATCH}"
    fi
    if [ ${#SW_VER_BLD} -eq 1 ] ; then
        FW_VER="${FW_VER}0${SW_VER_BLD}"
    else
        FW_VER="${FW_VER}${SW_VER_BLD}"
    fi
    # echo "${FW_VER}"

    # For now, we will only modify/set the FW name, not the GW name
    VNAME="CONFIG_VENDOR_ARRIS_FW_NAME"                                          # the variable name we want to modify
    DATE=$(date +%m%d%y)
    FW_POSTNAME="_"$DATE"_"
    CFG_VENDOR_FW_NAME_VAL="${FW_PRENAME}${FW_VER}${FW_POSTNAME}${HW}.${FW_BLDEXT}${FW_CERT}"    # the value it should get set to
    # echo "${VNAME}=${CFG_VENDOR_FW_NAME_VAL}"
    eval "sed -i -r 's|(# ${VNAME} is not set\|${VNAME}=).*|${VNAME}=\"${CFG_VENDOR_FW_NAME_VAL}\"|g'" ${BLDCFGFILE}
    # cat ${BLDCFGFILE} | grep -E "CONFIG_VENDOR_ARRIS_(F|G)W_"

    #Set GW Name
    CFG_VENDOR_GW_NAME_VAL="${FW_PRENAME}${FW_VER}${FW_POSTNAME}ARRIS_GW"
    sed -i "s|CONFIG_VENDOR_ARRIS_GW_NAME.*|CONFIG_VENDOR_ARRIS_GW_NAME=\"$CFG_VENDOR_GW_NAME_VAL\"|g" ${BLDCFGFILE}
    
    if [ "$HW" = "" ] ; then
        echo "Missing Hardware type"
        display_arm_usage

        return 1;
    fi

    #clean up vars
    unset PLATFORM
    unset SDK
    unset MTA
    unset HW
    unset CERT

    echo "Now set buildconfig"
    genconf ../defconfig/buildconfig
    bitbake virtual/core-image-gateway
 
    #Add ARRIS header
    #addhdr_arm $PLATFORM $SDK $HW

}

bld_atom()
{
    if [ $# -ne 2 ]; then
       display_usage
       return 
    fi
    
    check_platform $1
    check_hw_type $2
    if [ $IS_PLATFORM_VALID ] && [ $IS_HW_VALID ]; then
      #echo "Valid hw type $1"

      BUILD_PATH=$(pwd)
      #export TEMPLATECONF=$BUILD_PATH/../yocto/meta-arrisgw/conf
       
      #source ../yocto/oe-init-build-env
      if [ "$1" = "puma6" ] ; then
         bitbake core-image-gateway
      else
         bitbake core-image-cougarmountain         
      fi
      
      #Put on arris header
      addhdr $1 $2

   else
      display_usage
   fi

}


addhdr_arm()
{
   BUILD_PATH=$(pwd)
   PLATFORM_VER=$1
   SDK=$2
   HW_VER=$3

   check_platform $1
   check_sdk $2
   check_hw_type $3

   if [ $IS_PLATFORM_VALID ] && [ $IS_SDK_VALID ] && [ $IS_HW_VALID ]; then

      IMAGE_DIR="$BUILD_PATH/tmp/deploy/images/$PLATFORM_VER"
      ARM_IMAGE="$IMAGE_DIR/$SDK.$PLATFORM_VER.img"
      GW_IMAGE="$IMAGE_DIR/$SDK.$PLATFORM_VER-gw.sqfs"

      echo "$IMAGE_DIR"
      echo "$ARM_IMAGE"
      
      ADD_HEADER="$BUILD_PATH/../arris_tools/mkarrsimg.linux"
      PACKAGE_ATOM="$BUILD_PATH/../arris_tools/pkgAtom.sh"
 
      ATOM_IMAGE="/opt/gitatomtools/binaries/atom_image_$HW_VER"
      #Create pkg direcotry if it does not exist. If it doesn, errase theold one and start over.
      if [ ! -d "pkg" ]
      then
         mkdir pkg
      else
         rm -rf pkg
         mkdir pkg
      fi
      cd pkg
      mkdir release 
      cd release
      cp $GW_IMAGE gwImage
      cp $ARM_IMAGE armImage
      
      if [ $HW_VER = "16xx" ] ; then
         $ADD_HEADER armImage arris_arm.$SDK.$HW_VER.img $HEADER_BZIMAGE_M16XX

       elif [ $HW_VER = "1682v1" ] ; then
          $ADD_HEADER armImage arris_arm.$SDK.$HW_VER.img $HEADER_BZIMAGE_M1682V1

       elif [ $HW_VER = "1682" ] ; then
          $ADD_HEADER gwImage tmp_gwImage $ARM_HEADER_GW_M1682
          #Create GW image with header next flag=1 to attach to atom
          $ADD_HEADER gwImage tmp_gwImage_with_atom $ARM_HEADER_GW_M1682_WITH_ATOM

          $ADD_HEADER armImage tmp_armImage $ARM_HEADER_BZIMAGE_M1682
          cat tmp_armImage tmp_gwImage > arris_arm.$SDK.$HW_VER.img  

          #create combined image with GW header next flag=1 to attach to atom
          cat tmp_armImage tmp_gwImage_with_atom > arris_arm.$SDK.$HW_VER.with_atom.img
       elif [ $HW_VER = "mg24xx" ] ; then
          $ADD_HEADER armImage arris_arm.$SDK.$HW_VER.img $HEADER_BZIMAGE_M24MG

       elif [ $HW_VER = "tg24xx" ] ; then
          $ADD_HEADER armImage arris_arm.$SDK.$HW_VER.img $HEADER_BZIMAGE_M24TG
       else
          echo "$HW_VER -> Bad or missing hardware variant"
          echo "Supported HW variants are: 16xx, 1682v1, 1682, mg24xx, tg24xx"
       fi

       #put together monolithic image
       cat arris_arm.$SDK.$HW_VER.with_atom.img /opt/gitatomtools/binaries/arris_atom.$HW_VER.img > arris_arm_atom.$SDK.$HW_VER.img
       #clean up
       rm armImage;rm gwImage;rm tmp_armImage;rm tmp_gwImage;rm tmp_gwImage_with_atom;rm arris_arm.$SDK.$HW_VER.with_atom.img

       cd $WORKSPACE_PATH/build
   fi
}

addhdr()
{
    BUILD_PATH=$(pwd)

    PLATFORM_VER=$1
    HW_VER=$2

    check_platform $1
    check_hw_type $2
    if [ $IS_PLATFORM_VALID ] && [ $IS_HW_VALID ]; then
 
    #expecting to be in the build directory
       if [ $PLATFORM_VER = "puma6" ] ; then
          IMAGE_DIR="$BUILD_PATH/tmp/deploy/images/intelce"
          ATOM_IMAGE="$IMAGE_DIR/bzImage-intelce.bin"
          ROOTFS_TAR="$IMAGE_DIR/core-image-gateway-intelce.tar.bz2"
       elif [ $PLATFORM_VER = "puma7" ] ; then
          IMAGE_DIR="$BUILD_PATH/tmp/deploy/images/cougarmountain"
          ATOM_IMAGE="$IMAGE_DIR/bzImage-cougarmountain.bin"
          ROOTFS_TAR="$IMAGE_DIR/core-image-cougarmountain-cougarmountain.tar.bz2"

       fi

       ADD_HEADER="$BUILD_PATH/../arris_tools/mkarrsimg.linux"
       PACKAGE_ATOM="$BUILD_PATH/../arris_tools/pkgAtom.sh"

       #expecting to be in the build directory

       #Create pkg direcotry if it does not exist. If it doesn, errase theold one and start over.
       if [ ! -d "pkg" ]
       then
          mkdir pkg
       else
          rm -rf pkg
          mkdir pkg
       fi
       cd pkg
       cp $ATOM_IMAGE bzImage

       if [ ! -d "rootfs" ]
       then
          mkdir rootfs
       fi
       cd rootfs
       tar -xjf $ROOTFS_TAR
       #cp $NVRAM_FILE etc/init.d/nvram
       #chmod a+x etc/init.d/nvram
       cd ../
	   # remove the usr/include as it's not needed (we save around 3 MB by removing it) 
	   rm  -rf rootfs/usr/include	
       $PACKAGE_ATOM rootfs bzImage $BUILD_PATH/../arris_tools

   
       if [ $HW_VER = "16xx" ] ; then
          $ADD_HEADER bzImage tmp_bzImage $HEADER_BZIMAGE_M16XX
          $ADD_HEADER release/pumaAtomRdk_rootfs.img release/tmp_pumaAtomRdk_rootfs.img $HEADER_ROOTFS_M16XX
          cat tmp_bzImage release/tmp_pumaAtomRdk_rootfs.img > release/arris_atom.16xx.img
          rm tmp_bzImage
          rm release/tmp_pumaAtomRdk_rootfs.img

       elif [ $HW_VER = "1682v1" ] ; then
          $ADD_HEADER bzImage tmp_bzImage $HEADER_BZIMAGE_M1682V1
          $ADD_HEADER release/pumaAtomRdk_rootfs.img release/tmp_pumaAtomRdk_rootfs.img $HEADER_ROOTFS_M1682V1
          cat tmp_bzImage release/tmp_pumaAtomRdk_rootfs.img > release/arris_atom.1682v1.img
          rm tmp_bzImage
          rm release/tmp_pumaAtomRdk_rootfs.img

       elif [ $HW_VER = "1682" ] ; then
          $ADD_HEADER bzImage tmp_bzImage $HEADER_BZIMAGE_M1682
          $ADD_HEADER release/pumaAtomRdk_rootfs.img release/tmp_pumaAtomRdk_rootfs.img $HEADER_ROOTFS_M1682
          cat tmp_bzImage release/tmp_pumaAtomRdk_rootfs.img > release/arris_atom.1682.img
          rm tmp_bzImage
          rm release/tmp_pumaAtomRdk_rootfs.img

       elif [ $HW_VER = "mg24xx" ] ; then
          $ADD_HEADER bzImage tmp_bzImage $HEADER_BZIMAGE_M24MG
          $ADD_HEADER release/pumaAtomRdk_rootfs.img release/tmp_pumaAtomRdk_rootfs.img $HEADER_ROOTFS_M24MG
          cat tmp_bzImage release/tmp_pumaAtomRdk_rootfs.img > release/arris_atom.mg24xx.img
          rm tmp_bzImage
          rm release/tmp_pumaAtomRdk_rootfs.img

       elif [ $HW_VER = "tg24xx" ] ; then
          $ADD_HEADER bzImage tmp_bzImage $HEADER_BZIMAGE_M24TG
          $ADD_HEADER release/pumaAtomRdk_rootfs.img release/tmp_pumaAtomRdk_rootfs.img $HEADER_ROOTFS_M24TG
          cat tmp_bzImage release/tmp_pumaAtomRdk_rootfs.img > release/arris_atom.tg24xx.img
          rm tmp_bzImage
          rm release/tmp_pumaAtomRdk_rootfs.img

       else
          echo "$HW_VER -> Bad or missing hardware variant"
          echo "Supported HW variants are: 16xx, 1682v1, 1682, mg24xx, tg24xx"
       fi

       cd ../
   else
      echo "Wrong platform or header type. platform: $1, hw: $2"
      echo "Usage: add_hdr <platfrom_type> <hw_type>"
   fi


}

set_arris_repo_vars()
{
    # Verify we've been passed two parameters: platform and code train
    # and that they both have valid values
    check_function_parms $1 $2
    if [ $? != 0 ]
    then
       return 1
    fi

    haveerror="n"
    PLATFORM=$1
    CODETRAIN=$2

    case "$PLATFORM" in
        puma6) 
            case "$CODETRAIN" in

            dev) export ARRIS_BRANCH="atom_dev"
            ;;

            rdkb) export ARRIS_BRANCH="atom_dev_rdk-b"
            ;;

            rdkb_20) export ARRIS_BRANCH="atom_dev_rdk-b_20"
            ;;

            *) echo "" 
               echo "ERROR in set_arris_repo_vars, invalid Platform/Codetrain combination ($1, $2)"
               haveerror="y"
            ;;
            esac
        ;;

        puma7)
           export ARRIS_BRANCH="atom_dev_puma7"
        ;;

        *) echo ""
           echo "ERROR in set_arris_repo_vars, invalid Platform value"
           haveerror="y"
       ;;
    esac

    if [[ $haveerror == "y" ]]
    then 
       return 1
    else
echo "exporting ARRIS_GIT"
       export ARRIS_GIT="ttmgit.arrisi.com/TTM"
       return 0
    fi
}


# THIS IS OBSOLETE NOW. KEEPING FOR A BIT.
set_repoparms_to_localconf()
{
    # This function writes the export of ARRIS_GIT and ARRIS_BRANCH values into
    # build/conf/local.conf, and also writes an export of an amended BB_ENV_EXTRAWHITE
    # that includes ARRIS_GIT and ARRIS_BRANCH to build/conf/local.conf
    # Must have ARRIS_GIT and ARRIS_BRANCH environment variables set to run this function
    # run set_arris_repo_vars before running this function. Cannot run it here, or
    # mkrepo breaks. Could add a third parameter to this function to tell it whether it's 
    # being called from mkrepo, and then run set_arris_repo_vars from here if we're not
    # being called by mkrepo. Don't have time for more modifications to do it now. LR
    ok="n"
    myid=`id -un`
    if [[ `basename $(pwd)` != "build" ]]
    then
        export WORKSPACE_PATH=$(pwd)
    else
        export WORKSPACE_PATH=`dirname $(pwd)`
    fi
 
    if [[ ! -d "$WORKSPACE_PATH/yocto" ]]
    then
        echo "ERROR - you must be in your workspace or your workspace/build directory"
        echo "cd to your workspace and try again"
        return 1
    fi

    export BUILD_PATH="$WORKSPACE_PATH"/build
    echo "BUILD_PATH=$BUILD_PATH"
 
    if [[ ! -e $BUILD_PATH/conf/local.conf ]]
    then
        echo "ERROR - set_repoparms_to_local.conf"
        echo "Yocto build directory is not yet set up!"
        echo "cd to your project/workspace directory and run 'set_yocto puma6 || puma7'."
        return 1
    fi
    
    
    if [[ `grep 'ARRIS_GIT' $BUILD_PATH/conf/local.conf` ]]
    then
        echo "INFO: ARRIS_GIT exists in local.conf, changing the value to $ARRIS_GIT"
        # using : as the sed separator because there is a / in the vaue of ARRIS_GIT and sed doesn't like it
        sed -i "s:export ARRIS_GIT=.*$:export ARRIS_GIT=\"$ARRIS_GIT\":" $BUILD_PATH/conf/local.conf 
    else
        echo "export ARRIS_GIT=\"$ARRIS_GIT\"" >> $BUILD_PATH/conf/local.conf
    fi
    
    if [[ `grep 'ARRIS_BRANCH' $BUILD_PATH/conf/local.conf` ]]
    then
       echo "INFO: ARRIS_BRANCH exists in local.conf, changing the value to $ARRIS_BRANCH"
       sed -i "s/export ARRIS_BRANCH=.*$/export ARRIS_BRANCH=\"$ARRIS_BRANCH\"/" $BUILD_PATH/conf/local.conf 
    else
        echo "export ARRIS_BRANCH=\"$ARRIS_BRANCH\"" >> $BUILD_PATH/conf/local.conf
    fi
    
    if [[ `grep 'BB_ENV_EXTRAWHITE' $BUILD_PATH/conf/local.conf` == "" ]]
    then
       echo "export BB_ENV_EXTRAWHITE=\"$BB_ENV_EXTRAWHITE ARRIS_GIT ARRIS_BRANCH\""  >> $BUILD_PATH/conf/local.conf
    fi

    if [[ ! "$BB_ENV_EXTRAWHITE" =~ /ARRIS_GIT/ ]]
    then
         export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE ARRIS_GIT ARRIS_BRANCH"
    fi

    return 0
}
# END OBSOLETE

set_repoparms_to_env()
{
    # This function exports the values of ARRIS_GIT and ARRIS_BRANCH to the bash shell
    # and updates the value of BB_ENV_EXTRAWHITE to INCLUDE ARRIS_GIT ARRIS_BRANCH
    # WORKSPACE_PATH and DEV_OVERRIDE
    ok="n"
    myid=`id -un`
    if [[ `basename $(pwd)` != "build" ]]
    then
        export WORKSPACE_PATH=$(pwd)
    else
        export WORKSPACE_PATH=`dirname $(pwd)`
    fi
 
    if [[ ! -d "$WORKSPACE_PATH/yocto" ]]
    then
        echo "ERROR - you must be in your workspace or your workspace/build directory"
        echo "cd to your workspace and try again"
        return 1
    fi

    export ARRIS_GIT="$ARRIS_GIT"
    export ARRIS_BRANCH="$ARRIS_BRANCH"
    export WORKSPACE_TYPE="$WORKSPACE_TYPE"
    export PLATFORM="$PLATFORM_VER" 
    #export DEV_OVERRIDE="nooverride"  # default value
    export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE WORKSPACE_PATH ARRIS_GIT ARRIS_BRANCH DEV_OVERRIDE"
    

    return 0
}

check_current_path()
{
   # This function checks that the user is in a valid Yocto workspace or 
   # workspace/build directory

   # Note: this function assumes that the workspace always has a directory
   # under it called "yocto". If that ever changes, need to update this function - LR

   if [[ `basename $(pwd)` != "build" ]]
   then
       export WORKSPACE_PATH=$(pwd)
   else
       export WORKSPACE_PATH=`dirname $(pwd)`
   fi

   if [[ ! -d "$WORKSPACE_PATH/yocto" ]]
   then
       echo "ERROR - you must be in your workspace"
       echo "cd to your workspace and try again"
       return 1
   else
       return 0
   fi
}

check_function_parms()
{
    # This function verifies that a valid Platform value has been passed into $1,
    # and a valid Code Train value has been passed into $2. Multiple functions
    # in this file need those two parameters. Putting this check in one place,
    # so we only have one place to update when we add more Platforms and Code Trains

    if [[ $# -lt 2 ]]
    then
        echo ""
        echo "ERROR - incorrect number of parameters supplied."
        echo "Required parameters are Platform and Code Train."
        echo "Valid Platform values: puma6 || puma7"
        echo "Valid Code Train values: dev, rdkb"
        return 1
    fi

    PLATFORM=$1
    CODETRAIN=$2

    haveerror="n"
    case "$PLATFORM" in
        puma6) 
            case "$CODETRAIN" in

                dev) export ARRIS_BRANCH="atom_dev"
                ;;

                rdkb) export ARRIS_BRANCH="atom_dev_rdk-b"
                ;;
                rdkb_20) export ARRIS_BRANCH="atom_dev_rdk-b_20"
                ;;

                master) export ARRIS_BRANCH="master"
                ;;

                ct) export ARRIS_BRANCH="friendly3_to_ct"
                ;;
               
                intel) export ARRIS_BRANCH="$INTEL_DROP_BRANCH"
                ;;

                int) export ARRIS_BRANCH="arm_int"
                ;;

                int_ct) export ARRIS_BRANCH="arm_int_ct"
                ;;

                int_merge_10192015) export ARRIS_BRANCH="arm_int_ct"
                ;;

                *) echo "" 
                   echo "ERROR invalid Codetrain for pum6: $1, $2"
                   echo "Available values: dev, rdkb "
                   haveerror="y"
                ;;
            esac
        ;;

        puma7)
           export ARRIS_BRANCH="atom_dev_puma7"
        ;;

        *) echo ""
           echo "ERROR invalid Platform value: $1"
           echo "Available values are: puma6 || puma7"
           haveerror="y"
       ;;
    esac

    if [[ "$haveerror" == "y" ]]
    then
        return 1
    else
        return 0
    fi
} 

get_comp_list()
{
   #Pull in DEV_OVERRIDE var from build/conf/local.conf
   BUILD_CONF_PATH="$WORKSPACE_PATH/build/conf/local.conf"
   IN=$(grep "DEV_OVERRIDE" $BUILD_CONF_PATH)

   #Store IFS
   OIFS=$IFS

   #Parse DEV_OVERRIDE string by space delimeter. Store in array 'arr'
   IFS=' ' read -a arr <<< "$IN"

   #List of local components will be third argument
   COMPLIST=${arr[2]}

   #Remove quotes from string
   COMPLIST_STRIP=$(echo $COMPLIST | sed 's/"//g')

   #Reset IFS
   IFS=$OIFS

}

open_repo_help()
{
   echo "open_repo [-p|pull] <arris_component>"
   echo "-p, git clone arris component argument to current directory"
   echo "List of available arris components"
   echo $LIST_ARRIS_COMP

}

open_repo()
{
   if [ $# -eq 0 ]; then
      open_repo_help
   fi

   OPTIND=1

   while getopts ":p:" opt; do
      case $opt in
         p | pull)
            #Pull down git repo locally
            git clone git@ttmgit.arrisi.com:TTM/$OPTARG.git -b $ARRIS_BRANCH
            shift
            ;;
         \?)
            open_repo_help
            ;;
         :)
            echo "Option -$OPTARG requires an argument"
            open_repo_help
            return 1
            ;;
      esac
   done
 
   #Pull in DEV_OVERRIDE var from build/conf/local.conf
   BUILD_CONF_PATH="$WORKSPACE_PATH/build/conf/local.conf"
   #IN=$(grep "DEV_OVERRIDE" $BUILD_CONF_PATH)

   #Add "dev" to the end of input arg component
   INPUT_COMP="$1dev"

   #Get list of components in DEV_OVERRIDE
   get_comp_list

   if [ "$COMPLIST_STRIP" = "nooveride" ] ; then
      #DEV_OVERRIDES is set to "nooveride". So just replace with new component
      sed -i "s|DEV_OVERRIDE =.*|DEV_OVERRIDE = \"$INPUT_COMP\"|g" $BUILD_CONF_PATH
   else
      #Already some components in DEV_OVERRIDE. Need to add new component to the list

      #Store IFS
      OIFS=$IFS
      #Parse component list by ':'
      IFS=':' read -a arr2 <<< "$COMPLIST_STRIP"

      #Get number of components in list
      NUM_COMP=${#arr2[@]}

      IS_COMP_LISTED=false

      #Go through list of components that are already being worked on locally
      for ((i=0; i<$NUM_COMP; i++ ))
      do
         if [ "$INPUT_COMP" = ${arr2[$i]} ] ; then
            echo "Alrady have component $INPUT_COMP listed"
            IS_COMP_LISTED=true
         fi
      done

      #If the new component is not already in the list then add it to DEV_OVERRIDE
      if [ "$IS_COMP_LISTED" = false ] ; then
         if [ "$COMPLIST_STRIP" = "nooverride" ] ; then
            COMPLIST_STRIP=$INPUT_COMP
         else
            COMPLIST_STRIP=$COMPLIST_STRIP":"$INPUT_COMP
         fi
         echo "Adding new component with DEV_OVERRIDE=$COMPLIST_STRIP"
         sed -i "s|DEV_OVERRIDE =.*|DEV_OVERRIDE = \"$COMPLIST_STRIP\"|g" $BUILD_CONF_PATH
      fi

      #Reset IFS
      IFS=$OIFS

   fi

   #Clean up args
   shift
}

close_repo()
{
   if [ $# -ne 1 ]; then
      echo "close_repo <arris_component>"
      echo "List of available arris components"
      echo $LIST_ARRIS_COMP
      return
   fi

   #Pull in DEV_OVERRIDE var from build/conf/local.conf
   BUILD_CONF_PATH="$WORKSPACE_PATH/build/conf/local.conf"

   get_comp_list

   #Add "dev" to the end of input arg component
   INPUT_COMP="$1dev"

   #Store IFS
   OIFS=$IFS
   #Parse component list by ':'
   IFS=':' read -a arr <<< "$COMPLIST_STRIP"

   NUM_COMP=${#arr[@]}

   OUT_COMPLIST=""
   #Go through list of components that are already being worked on locally
   for ((i=0; i<$NUM_COMP; i++ ))
   do
      #if we found a match to input comp, don't add it to the list
      if [ "$INPUT_COMP" != ${arr[$i]} ] ; then
         OUT_COMPLIST=$OUT_COMPLIST":"${arr[$i]}
      fi
   done

   if [ "$OUT_COMPLIST" = "" ] ; then
      sed -i "s|DEV_OVERRIDE =.*|DEV_OVERRIDE = \"nooverride\"|g" $BUILD_CONF_PATH
   else
      #Remove any leading : at the beginning of list
      OUT_COMPLIST_STRIP=$(echo $OUT_COMPLIST | sed 's/^://')
      sed -i "s|DEV_OVERRIDE =.*|DEV_OVERRIDE = \"$OUT_COMPLIST_STRIP\"|g" $BUILD_CONF_PATH

   fi

   echo "Closing repo $1 for editing and removing from DEV_OVERRIDE"
   grep "DEV_OVERRIDE" $BUILD_CONF_PATH

   #Reset IFS
   IFS=$OIFS

   #Clean up args
   shift
}

bld_repo()
{
    if [ $# -ne 1 ]; then
       echo "Usage: bld_repo <arris_component>"
       echo "List of available arris components"
       echo $LIST_ARRIS_COMP
       return
    fi

    cd $WORKSPACE_PATH/build/arris_source/
    tar -czf $1.tgz $1
    mv $1.tgz $WORKSPACE_PATH/build/arris_source/files
    cd $WORKSPACE_PATH/build/

    bitbake -c clean $1 
    bitbake -c fetch $1 
    bitbake -c compile $1 
 
    shift
}

update_repo()
{
   git pull origin $ARRIS_BRANCH
}

show_repo()
{
   grep "DEV_OVERRIDE" "$WORKSPACE_PATH/build/conf/local.conf"
}

gdiff()
{
   git diff HEAD@{1} $1
}

# Alias's for moving to directories in your workspace
alias wbase='cd $WORKSPACE_PATH'
alias wbuild='cd $WORKSPACE_PATH/build'
alias wtools='cd $WORKSPACE_PATH/arris_tools'
alias wsource='cd $WORKSPACE_PATH/build/arris_source'
alias larris='cd $WORKSPACE_PATH/yocto/meta-arrisgw'
alias lintel='cd $WORKSPACE_PATH/yocto/meta-intelce'

# Cleans control characters from all files
alias cleanpatch='find . -name "*.patch" -type f -exec dos2unix {} \;'

