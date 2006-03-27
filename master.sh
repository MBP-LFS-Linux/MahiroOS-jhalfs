#!/bin/bash
# $Id$
set -e


#>>>>>>>>>>>>>>>ERROR TRAPPING >>>>>>>>>>>>>>>>>>>>
#-----------------------#
simple_error() {        # Basic error trap.... JUST DIE
#-----------------------#
  # If +e then disable text output
  if [[ "$-" =~ "e" ]]; then
    echo -e "\n${RED}ERROR:${GREEN} basic error trapped!${OFF}\n" >&2
  fi
}

see_ya() {
    echo -e "\n\t${BOLD}Goodbye and thank you for choosing ${L_arrow}JHALFS-X${R_arrow}\n"
}
##### Simple error TRAPS
# ctrl-c   SIGINT
# ctrl-y
# ctrl-z   SIGTSTP
# SIGHUP   1 HANGUP
# SIGINT   2 INTRERRUPT FROM KEYBOARD Ctrl-C
# SIGQUIT  3
# SIGKILL  9 KILL
# SIGTERM 15 TERMINATION
# SIGSTOP 17,18,23 STOP THE PROCESS
#####
set -e
trap see_ya 0
trap simple_error ERR
trap 'echo -e "\n\n${RED}INTERRUPT${OFF} trapped\n" &&  exit 2'  1 2 3 15 17 18 23
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


if [ ! -L $0 ] ; then
  echo "${nl_}${tab_}${BOLD}${RED}This script cannot be called directly: EXITING ${OFF}${nl_}"
  exit 1
fi

     PROGNAME=$(basename $0)
   COMMON_DIR="common"
   PACKAGE_DIR=$(echo $PROGNAME | tr [a-z] [A-Z])
       MODULE=$PACKAGE_DIR/master.sh
MODULE_CONFIG=$PACKAGE_DIR/config

echo -n "Loading common-functions module..."
source $COMMON_DIR/common-functions
[[ $? > 0 ]] && echo " $COMMON_DIR/common-functions did not load.." && exit
echo "OK"
#

echo -n "Loading masterscript conf..."
source $COMMON_DIR/config
[[ $? > 0 ]] && echo "$COMMON_DIR/conf did not load.." && exit
echo "OK"
#
echo -n "Loading config module <$MODULE_CONFIG>..."
source $MODULE_CONFIG
[[ $? > 0 ]] && echo "$MODULE_CONFIG did not load.." && exit 1
echo "OK"
#
echo -n "Loading code module <$MODULE>..."
source $MODULE
[[ $? > 0 ]] && echo "$MODULE did not load.." && exit 2
echo "OK"
#
echo "---------------${nl_}"


#===========================================================
# If the var BOOK contains something then, maybe, it points
# to a working doc.. set WC=1, else 'null'
#===========================================================
WC=${BOOK:+1}
#===========================================================


#*******************************************************************#
echo -n "Loading function <func_check_version.sh>..."
source $COMMON_DIR/func_check_version.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
echo "OK"

echo -n "Loading function <func_validate_configs.sh>..."
source $COMMON_DIR/func_validate_configs.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
echo "OK"
echo "---------------${nl_}"


###################################
###		MAIN		###
###################################

# Evaluate any command line switches

while test $# -gt 0 ; do
  case $1 in
    --version | -V )
        clear
        echo "$version"
        exit 0
      ;;

    --help | -h )
        if [[ "$PROGNAME" = "blfs" ]]; then
          blfs_usage
        else
          usage
        fi
      ;;

    --LFS-version | -L )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        dev* | SVN | trunk )
          LFSVRS=development
          ;;
	*) if [[ "$PROGNAME" = "lfs" ]]; then
	     case $1 in
               6.1.1 )
                 echo "For stable 6.1.1 book, please use jhalfs-0.2."
                 exit 0
                ;;
               alpha*) LFSVRS=alphabetical  ;;
               udev*)  LFSVRS=udev_update   ;;
               * )     echo "$1 is an unsupported version at this time." ;;
	     esac
	   else
	     echo "The requested version, ${L_arrow} ${BOLD}$1${OFF} ${R_arrow}, is undefined in the ${BOLD}$(echo $PROGNAME | tr [a-z] [A-Z])${OFF} series."
             exit 0
           fi
          ;;
      esac
      ;;

    --directory | -d )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      BUILDDIR=$1
      JHALFSDIR=$BUILDDIR/jhalfs
      LOGDIR=$JHALFSDIR/logs
      MKFILE=$JHALFSDIR/Makefile
      ;;

   
    --download-client | -D )
      echo "The download feature is temporarily disable.."
      exit
      test $# = 1 && eval "$exit_missing_arg"
      shift
      DL=$1
      ;;

    --working-copy | -W )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1/patches.ent ] ; then
        WC=1
        BOOK=$1
      else
        echo -e "\nLook like $1 isn't a supported working copy."
        echo -e "Verify your selection and the command line.\n"
        exit 1
      fi
      ;;

    --testsuites | -T )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        0 | 1 | 2 | 3 )
          TEST=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid testsuites level value."
          echo -e "You must to use 0, 1, 2, or 3.\n"
          exit 1
          ;;
      esac
      ;;

    --get-packages | -P )  HPKG=1    ;;
    --run-make | -M )      RUNMAKE=1 ;;
    --no-strip )           STRIP=0   ;;
    --no-vim-lang )        VIMLANG=0 ;;
    --rebuild )            CLEAN=1   ;;

    --page_size )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        letter | A4 )
          PAGE=$1
          ;;
        * )
          echo "$1 isn't a supported page size."
          exit 1
          ;;
      esac
      ;;

    --timezone )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f /usr/share/zoneinfo/$1 ] ; then
        TIMEZONE=$1
      else
        echo -e "\nLooks like $1 isn't a valid timezone description."
        echo -e "Verify your selection and the command line.\n"
        exit 1
      fi
      ;;

    --fstab )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        FSTAB=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    --kernel-config | -C )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        CONFIG=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    * )
      if [[ "$PROGNAME" = "blfs" ]]; then
        blfs_usage
      else
        usage
      fi
      ;;
  esac
  shift
done

# Find the download client to use, if not already specified.

if [ -z $DL ] ; then
  if [ `type -p wget` ] ; then
    DL=wget
  elif [ `type -p curl` ] ; then
    DL=curl
  else
    eval "$no_dl_client"
  fi
fi

#===================================================
# Set the document location...
# BOOK is either defined in
#   xxx.config
#   comand line
#   default
# If set by conf file or cmd line leave it
# alone otherwise load the default version
#===================================================
BOOK=${BOOK:=$PROGNAME-$LFSVRS}
#===================================================


# Check for minumum gcc and kernel versions
#check_requirements  1 # 0/1  0-do not display values.
check_version "2.6.2" "`uname -r`"         "KERNEL"
check_version "3.0"   "$BASH_VERSION"      "BASH"
check_version "3.0"   "`gcc -dumpversion`" "GCC"
tarVer=`tar --version`
check_version "1.15.0" "${tarVer##* }"      "TAR"
echo "---------------${nl_}"

validate_config     1 # 0/1  0-do not display values
echo "---------------${nl_}"

echo -n "Are you happy with that settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Fix the configuration options and rerun the script.${nl_}"
  exit 1
fi

# Prevents setting "-d /" by mistake.

if [ $BUILDDIR = / ] ; then
  echo -ne "\nThe root directory can't be used to build LFS.\n\n"
  exit 1
fi

# If $BUILDDIR has subdirectories like tools/ or bin/, stop the run
# and notify the user about that.

if [ -d $BUILDDIR/tools -o -d $BUILDDIR/bin ] && [ -z $CLEAN ] ; then
  eval "$no_empty_builddir"
fi

# If requested, clean the build directory
clean_builddir

if [[ ! -d $JHALFSDIR ]]; then
  mkdir -pv $JHALFSDIR
fi

if [[ "$PWD" != "$JHALFSDIR" ]]; then
  cp -v $COMMON_DIR/makefile-functions $JHALFSDIR/
  if [[ -n "$FILES" ]]; then
    # pushd/popd necessary to deal with mulitiple files
    pushd $PACKAGE_DIR
      cp -v $FILES $JHALFSDIR/
    popd
  fi
  sed 's,FAKEDIR,'$BOOK',' $PACKAGE_DIR/$XSL > $JHALFSDIR/${XSL}
  export XSL=$JHALFSDIR/${XSL}
fi

if [[ ! -d $LOGDIR ]]; then
  mkdir -v $LOGDIR
fi
>$LOGDIR/$LOG
echo "---------------${nl_}"

get_book
echo "---------------${nl_}"

build_Makefile
echo "---------------${nl_}"

run_make

