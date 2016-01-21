#to!/bin/bash

function setup_tools
{
    # Pull down ATOM_TOOLS
    if [ ! -d "arris_tools" ] ; then
       git clone git@ttmgit.arrisi.com:TTM/arris_tools.git
    fi
    
    # Pull in main set of yocto scripts
    source arris_tools/yoctofunctions.sh

    # Verify we have the required passed in parameters
    check_function_parms $1 $2
    if [ $? != 0 ]
    then
       return 1
    fi


}

function mkrepo_arm
{
    setup_tools $1 $2
    mkrepo_arm_internal $1 $2

}

function mkrepo_atom
{
    setup_tools $1 $2
    mkrepo_atom_internal $1 $2

}

function srepo
{
   if [ $# -ne 1 ]; then
      echo "Usage: srepo <path_to_workspace>"
      echo "where <path_to_workspace> can be a relative or absolute path to your workspace, which"
      echo "must include a folder named 'arris_tools'"
      return 1
   fi

   if [ ! -d $1 ] ; then
       echo "Workspace $1 does not exist"
       return 1
   fi
   if [ ! -e $1/arris_tools/yoctofunctions.sh ] ; then
       echo "Script '$1/arris_tools/yoctofunctions.sh' cannot be found"
       return 1
   fi

   #Go into workspace
   cd $1

   #clear out input var
   shift

   # Pull in main set of yocto scripts
   source arris_tools/yoctofunctions.sh 

   srepo_internal 
}

function pull_intel_source
{
   if [ $# -ne 2 ]; then
      echo "Missing branch parameters"
      echo "Usage:   pull_intel_source <Intel branch> <internal branch>"
      echo "Example: pull_intel_source spd/puma7/atom/general/20150502-2015_ww18_cgm_sw0.2 r5.0-rc4"
      return
   fi

   repo init -u ssh://127.0.1.10/manifest -b $1 -m manifest-full.xml --mirror
   repo sync
   repo forall -c "git symbolic-ref refs/heads/$2 refs/heads/$1"
}

