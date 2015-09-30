#!/bin/bash
#
# author      : sde
# description : upgrade iorder...
#
# history:
#   2015/09/23 : 0.1 - initial version
#

DEBUG=0

ERR_NO_INPUT_PARAM=1
ERR_ONLY_ROOT=2
ERR_INVALID_OPTION=3
ERR_PARAMETER_REQUIRED=4
ERR_WRONG_VERSION=5
# some other errors
# .
# .
ERR_GENERAL=10

OK=0
ERROR=1

remote=~/Desktop/io-deploy/iorder-server.git/
localpath=~/Desktop/io-deploy/iorder/
err_commit=true

show_usage()
{
  echo
  echo "use: $(basename $0) [-l] | [-v <version_to_deploy>] | [-h]"
  echo "     -l ....................... show all versions"
  echo "     -v <version_to_deploy> ... deploy <version_to_deploy>"
  echo "     -h ....................... show this help"
}

exit_with_error()
{
  local retcode="$1"
  printf "\e[0;31merror: \e[0m"
  case $retcode in
    $ERR_NO_INPUT_PARAM)
      echo "input parameter is missing"
      show_usage
      ;;
    $ERR_ONLY_ROOT)
      echo "you must be root to deploy"
      ;;
    $ERR_INVALID_OPTION)
      echo "invaild option '-$OPTARG'"
      show_usage
      ;;
    $ERR_PARAMETER_REQUIRED)
      echo "option '-$OPTARG' requires an argument"
      show_usage
      ;;
    $ERR_WRONG_VERSION)
      echo "wrong version to deploy"
      ;;
    *)
      echo "error: unknown [$retcode]"
      ;;
  esac
  echo
  exit $retcode
}

roll_back()
{
  if [ $err_commit != true  ]
  then
  echo "An error has occured."
   case $err_commit in
     1) 
     ;;
     2)
     rmdir $localpath-$version
     ;;
     3) 
	    rm -rf $localpath-$version
     ;;
     4) 
	    rm -rf $localpath-$version'/iorder-server/.'
     ;;
     5)
     ;;
  esac
  fi    	
}

is_debug()
{
  [ "$DEBUG" = "1" -o "$DEBUG" = "true" ] && return 0 || return 1
}

is_version_number()
{
if ! [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
echo "Version must be a number!"
exit 1;
fi
}

ask_yes_no() {
  local retval
  echo -n "are you sure (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
  echo
  return $retval
}

check_version()
{
# if [ "$1" -ne "$1" ] 2>/dev/null
#   then
#    echo "ERROR: first paramter must be an integer."
#    exit ERR_WRONG_VERSION
#  fi


sub="\."
temp="${version//\./$sub}"
temp=$(git ls-remote -t "$remote" | grep "$temp")

if [ -z "$temp" ];
then 
  !
else
  :
fi

}

evaluate()
{
  if $1 -ne "0"
  then
    !
  else
    :
  fi
}

show_all_version()
{
  # TODO
  # get and show all version from the github
  echo ${remote}
  git ls-remote -t "${remote}" #"show all versions..."
}

deploy()
{
  local version="$1"
  is_debug && echo "DEBUG: version = '$version'"
  is_version_number "$version"
  check_version "$version"
  local result=$?
  echo "$result"
  if [ "$result" == "0"  ]; then
    #CHECK IF THE VERSION ALREADY EXITS ON OUR LOCAL
    if [ ! -d $localpath-$version ];then

      mkdir -p $localpath-$version || err_commit=1 
      evaluate $err_commit && cd $localpath || err_commit=2
      evaluate $err_commit && git clone --branch $version $remote || err_commit=3
      evaluate $err_commit && mv $localpath'iorder-server/' $localpath-$version || err_commit=5   ## TODO: DIRECTORY NOT EMPTY ERR
      evaluate $err_commit && rm -rf $localpath'iorder-server' || err_commit = 5

      if [ -d $localpath-"live" ];then
        if [ -d $localpath-"live_old" ];then
          rm -rf $localpath-"live_old"
        fi 
        mv $localpath-"live" $localpath-"live_old"
      fi

      $err_commit && ln -fs -f -s $localpath-$version $localpath-"live" || err_commit=6
  
      roll_back

   else

    echo "THE VERSION IS ALREADY INSTALLED ON YOUR DISC!"
    echo "Do you wish to set it as live version?"

    ask_yes_no
    local answer=$?

    if [ "$answer" == "0" ];then #YES

      echo "Setting up link for you."

      if [ -d $localpath-"live" ];then
        if [ -d $localpath-"live_old" ];then
          rm -rf $localpath-"live_old"
        fi 
        mv $localpath-"live" $localpath-"live_old"
      fi
      $err_commit && ln -fs -f -s $localpath-$version $localpath-"live" || err_commit=7 

    fi
  fi


 else
   echo "THAT VERSION DOES NOT EXIST!"
   exit ERR_WRONG_VERSION
 fi
}

#
# main
#

# some basic checks
[[ "$#" -eq 0 ]] && exit_with_error $ERR_NO_INPUT_PARAM
#[[ "$(whoami)" != "root" ]] && exit_with_error $ERR_ONLY_ROOT

while getopts ":dhlv:" opt; do
  case $opt in
    d)
      # enable debug
      DEBUG=1
      echo "DEBUG: enabled"
      ;;
    h)
      show_usage
      echo
      exit $OK
      ;;
    l)
      show_all_version
      ;;
    v)
      version="$OPTARG"
      deploy $version
      ;;
    \?)
      exit_with_error $ERR_INVALID_OPTION
      ;;
    :)
      exit_with_error $ERR_PARAMETER_REQUIRED
      ;;
  esac
done
shift $((OPTIND - 1))
# $1 contains the first arg now
