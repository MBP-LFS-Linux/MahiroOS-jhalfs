# $Id$

validate_target() {

  local -r ERROR_MSG_pt1='The variable \"${L_arrow}TARGET${R_arrow}\" value ${L_arrow}${BOLD}${TARGET}${R_arrow} is invalid for the ${L_arrow}${BOLD}${ARCH}${R_arrow} architecture'
  local -r ERROR_MSG_pt2='  check the config file ${BOLD}${GREEN}\<$(echo $PROGNAME | tr [a-z] [A-Z])/config\> or \<common/config\>${OFF}'

  local -r PARAM_VALS='TARGET: ${L_arrow}${BOLD}${TARGET}${OFF}${R_arrow}'
  local -r PARAM_VALS2='TARGET32: ${L_arrow}${BOLD}${TARGET32}${OFF}${R_arrow}'

  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG_pt1}`" >&2
    echo -e "`eval echo ${ERROR_MSG_pt2}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

 if [[ ! "${TARGET32}" = "" ]]; then
    [[ $verbose = "1" ]] && echo -e "`eval echo $PARAM_VALS2`"
 fi
 [[ $verbose = "1" ]] && echo -e "`eval echo $PARAM_VALS`"

 case "${ARCH}" in
   "x86")      [[ "${TARGET}" = "i486-pc-linux-gnu" ]] && return
               [[ "${TARGET}" = "i586-pc-linux-gnu" ]] && return
               [[ "${TARGET}" = "i686-pc-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "ppc")      [[ "${TARGET}" = "powerpc-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "mips")     [[ "${TARGET}" = "mipsel-unknown-linux-gnu" ]] && return
               [[ "${TARGET}" = "mips-unknown-linux-gnu"   ]] && return
        write_error_and_die
    ;;
   "sparc")    [[ "${TARGET}" = "sparcv9-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "sparcv8")  [[ "${TARGET}" = "sparc-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "x86_64-64") [[ "${TARGET}" = "x86_64-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "mips64-64")  [[ "${TARGET}" = "mipsel-unknown-linux-gnu" ]] && return
                 [[ "${TARGET}" = "mips-unknown-linux-gnu"   ]] && return
        write_error_and_die
    ;;
   "sparc64-64") [[ "${TARGET}" = "sparc64-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "alpha")      [[ "${TARGET}" = "alpha-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "x86_64")     [[ "${TARGET}"   = "x86_64-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "i686-pc-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "mips64")     [[ "${TARGET}"   = "mipsel-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "mipsel-unknown-linux-gnu" ]] && return
               
                 [[ "${TARGET}"   = "mips-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "mips-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "sparc64")   [[ "${TARGET}"   = "sparc64-unknown-linux-gnu" ]] && 
                [[ "${TARGET32}" = "sparcv9-unknown-linux-gnu" ]] && return
        write_error_and_die
    ;;
   "ppc64")    [[ "${TARGET}"   = "powerpc64-unknown-linux-gnu" ]] &&
               [[ "${TARGET32}" = "powerpc-unknown-linux-gnu"   ]] && return               
        write_error_and_die
    ;;
   *)  write_error_and_die
 esac
}


#----------------------------#
validate_config()    {       # Are the config values sane (within reason)
#----------------------------#
: <<inline_doc
      Validates the configuration parameters. The global var PROGNAME selects the
    parameter list.

    input vars: $1 0/1 0=quiet, 1=verbose output
    externals:  color constants
                PROGNAME (lfs,clfs,hlfs,blfs)
    modifies:   none
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  local -r blfs_PARAM_LIST="BUILDDIR SRC_ARCHIVE TEST LANG DEPEND"
  local -r hlfs_PARAM_LIST="BUILDDIR SRC_ARCHIVE TEST HPKG RUNMAKE STRIP PAGE TIMEZONE LC_ALL LANG         KEYMAP             FSTAB CONFIG MODEL GRSECURITY_HOST"
  local -r clfs_PARAM_LIST="BUILDDIR SRC_ARCHIVE TEST HPKG RUNMAKE STRIP PAGE TIMEZONE        LANG VIMLANG KEYMAP ARCH TARGET FSTAB CONFIG BOOT_CONFIG METHOD"
  local -r  lfs_PARAM_LIST="BUILDDIR SRC_ARCHIVE TEST HPKG RUNMAKE STRIP PAGE TIMEZONE        LANG VIMLANG                    FSTAB CONFIG"

  local -r ERROR_MSG_pt1='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid,'
  local -r ERROR_MSG_pt2=' check the config file ${BOLD}${GREEN}\<$(echo $PROGNAME | tr [a-z] [A-Z])/config\> or \<common/config\>${OFF}'
  local -r PARAM_VALS='${config_param}: ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

  local    PARAM_LIST=

  local config_param
  local validation_str
  local verbose=$1
  
  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG_pt1}`" >&2
    echo -e "`eval echo ${ERROR_MSG_pt2}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

  validate_str() {
     # This is the 'regexp' test available in bash-3.0..
     # using it as a poor man's test for substring
     [[ $verbose = "1" ]] && echo -e "`eval echo $PARAM_VALS`"
     if [[ ! "${validation_str}" =~ "x${!config_param}x" ]] ; then
       # parameter value entered is no good
       write_error_and_die
     fi
  }
  
  set +e
  for PARAM_GROUP in ${PROGNAME}_PARAM_LIST; do
    for config_param in ${!PARAM_GROUP}; do
      # This is a tricky little piece of code.. executes a cmd string.
      case $config_param in
        BUILDDIR) # We cannot have an <empty> or </> root mount point
            [[ $verbose = "1" ]] && echo -e "`eval echo $PARAM_VALS`"
            if [[ "xx x/x" =~ "x${!config_param}x" ]]; then
              write_error_and_die
            fi
            continue  ;;
        TIMEZONE)  continue;;
        MKFILE)    continue;;
        HPKG)      validation_str="x0x x1x";          validate_str; continue ;;
        RUNMAKE)   validation_str="x0x x1x";          validate_str; continue ;;
        TEST)      validation_str="x0x x1x x2x x3x";  validate_str; continue ;;
        STRIP)     validation_str="x0x x1x";          validate_str; continue ;;
        VIMLANG)   validation_str="x0x x1x";          validate_str; continue ;;
        DEPEND)    validation_str="x0x x1x x2x";      validate_str; continue ;;
        MODEL)     validation_str="xglibcx xuclibcx"; validate_str; continue ;;
        PAGE)      validation_str="xletterx xA4x";    validate_str; continue ;;
        GRSECURITY_HOST)  validation_str="x0x x1x";   validate_str; continue ;;
        METHOD)    validation_str="xchrootx xbootx";  validate_str; continue ;;
        ARCH)      validation_str="xx86x xx86_64x xx86_64-64x xsparcx xsparcv8x xsparc64x xsparc64-64x xmipsx xmips64x xmips64-64x xppcx xppc64x xalphax";  validate_str; continue ;;
        TARGET)    validate_target; continue ;;
      esac


      if [[ "${config_param}" = "LC_ALL" ]]; then
         [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ -z "${!config_param}" ]] && continue
          # See it the locale values exist on this machine
         if [[ "`locale -a | grep -c ${!config_param}`" > 0 ]]; then
           continue
         else  # If you make it this far then there is a problem
           write_error_and_die
         fi
      fi

      if [[ "${config_param}" = "LANG" ]]; then
         [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ -z "${!config_param}" ]] && continue
          # See it the locale values exist on this machine
         if [[ "`locale -a | grep -c ${!config_param}`" > 0 ]]; then
           continue
         else  # If you make it this far then there is a problem
           write_error_and_die
         fi
      fi     


      if [[ "${config_param}"  = "KEYMAP" ]]; then
         [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ "${!config_param}" = "none" ]] && continue
         if [[ -e "/usr/share/kbd/keymaps/${!config_param}" ]] && 
            [[ -s "/usr/share/kbd/keymaps/${!config_param}" ]]; then
            continue
         else
            write_error_and_die
         fi
      fi

      if [[ "${config_param}" = "SRC_ARCHIVE" ]]; then
         [[ $verbose = "1" ]] && echo -n "`eval echo $PARAM_VALS`"
         if [ ! -z ${SRC_ARCHIVE} ]; then
           if [ ! -d ${SRC_ARCHIVE} ]; then
             echo "   -- is NOT a directory"
	     write_error_and_die
           fi
           if [ ! -w ${SRC_ARCHIVE} ]; then
             echo -n "${nl_} [${BOLD}${YELLOW}WARN$OFF] You do not have <write> access to this directory, ${nl_}${tab_}downloaded files can not be saved in this archive"
           fi
        fi
        echo
        continue
      fi

      if [[ "${config_param}" = "FSTAB" ]]; then
         [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ -z "${!config_param}" ]] && continue
         if [[ -e "${!config_param}" ]] &&
            [[ -s "${!config_param}" ]]; then
           continue
         else
           write_error_and_die
         fi
      fi

      if [[ "${config_param}" = "BOOK" ]]; then
         [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ ! "${WC}" = 1 ]] && continue
         [[ -z "${!config_param}" ]] && continue
         if [[ -e "${!config_param}" ]] && 
            [[ -s "${!config_param}" ]]; then 
           continue
         else
           write_error_and_die
         fi
      fi

      if [[ "${config_param}" = "CONFIG" ]]; then
         [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
         [[ -z "${!config_param}" ]] && continue
         if [[ -e "${!config_param}" ]] && 
            [[ -s "${!config_param}" ]]; then
           continue
         else
           write_error_and_die
         fi
      fi

      if [[ "${config_param}" = "BOOT_CONFIG" ]]; then
        if [[ "${METHOD}" = "boot" ]]; then
           [[ $verbose = "1" ]] && echo "`eval echo $PARAM_VALS`"
           # There must be a config file when the build method is 'boot'
           [[ -e "${!config_param}" ]] && [[ -s "${!config_param}" ]] && continue
           # If you make it this far then there is a problem
          write_error_and_die
        fi
      fi
  done
  done

  set -e
  echo "$tab_***${BOLD}${GREEN} ${PARAM_GROUP%%_*T} config parameters look good${OFF} ***"
}
