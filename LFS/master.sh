#!/bin/bash

# $Id$

###################################
###	    FUNCTIONS		###
###################################


#############################################################


#----------------------------#
chapter4_Makefiles() {       #
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter4     ( SETUP ) ${R_arrow}"

# If $LUSER_HOME is already present in the host, we asume that the
# lfs user and group are also presents in the host, and a backup
# of their bash init files is made.
(
    cat << EOF
04_02-creatingtoolsdir:
	@\$(call echo_message, Building)
	@mkdir \$(MOUNT_PT)/tools && \\
	rm -f /tools && \\
	ln -s \$(MOUNT_PT)/tools /
	@\$(call housekeeping)

04_03-addinguser:  04_02-creatingtoolsdir
	@\$(call echo_message, Building)
	@if [ ! -d \$(LUSER_HOME) ]; then \\
		groupadd \$(LGROUP); \\
		useradd -s /bin/bash -g \$(LGROUP) -m -k /dev/null \$(LUSER); \\
	else \\
		touch luser-exist; \\
	fi;
	@chown \$(LUSER) \$(MOUNT_PT)/tools && \\
	chmod -R a+wt \$(MOUNT_PT)/\$(SCRIPT_ROOT) && \\
	chmod a+wt \$(SRCSDIR)
	@\$(call housekeeping)

04_04-settingenvironment:  04_03-addinguser
	@\$(call echo_message, Building)
	@if [ -f \$(LUSER_HOME)/.bashrc -a ! -f \$(LUSER_HOME)/.bashrc.XXX ]; then \\
		mv \$(LUSER_HOME)/.bashrc \$(LUSER_HOME)/.bashrc.XXX; \\
	fi;
	@if [ -f \$(LUSER_HOME)/.bash_profile  -a ! -f \$(LUSER_HOME)/.bash_profile.XXX ]; then \\
		mv \$(LUSER_HOME)/.bash_profile \$(LUSER_HOME)/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > \$(LUSER_HOME)/.bashrc && \\
	echo "umask 022" >> \$(LUSER_HOME)/.bashrc && \\
	echo "LFS=\$(MOUNT_PT)" >> \$(LUSER_HOME)/.bashrc && \\
	echo "LC_ALL=POSIX" >> \$(LUSER_HOME)/.bashrc && \\
	echo "PATH=/tools/bin:/bin:/usr/bin" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export LFS LC_ALL PATH" >> \$(LUSER_HOME)/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> \$(LUSER_HOME)/.bashrc && \\
	chown \$(LUSER):\$(LGROUP) \$(LUSER_HOME)/.bashrc
	@\$(call housekeeping)
EOF
) > $MKFILE.tmp

  chapter4=" 04_02-creatingtoolsdir 04_03-addinguser 04_04-settingenvironment"
}



#----------------------------#
chapter5_Makefiles() {
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter5     ( LUSER ) ${R_arrow}"

  for file in chapter05/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # If no testsuites will be run, then TCL, Expect and DejaGNU aren't needed
    case "${this_script}" in
      *tcl)       [[ "${TEST}" = "0" ]] && continue ;;
      *expect)    [[ "${TEST}" = "0" ]] && continue ;;
      *dejagnu)   [[ "${TEST}" = "0" ]] && continue ;;
      *stripping) [[ "${STRIP}" = "n" ]] && continue ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    # DO NOT append the changingowner script, it need be run as root.
    # A hack is necessary: create script in chap5 BUT run as a dependency for
    # SUDO target
    case "${this_script}" in
      *changingowner) runasroot="$runasroot ${this_script}" ;;
                   *) chapter5="$chapter5 ${this_script}" ;;
    esac

    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=04_04-settingenvironment ; fi

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    LUSER_wrt_target "${this_script}" "$PREV"

    # Run the script.
    # The changingowner script must be run as root.
    case "${this_script}" in
      *changingowner)  wrt_RunAsRoot "$file" ;;
      *)               LUSER_wrt_RunAsUser "$file" ;;
    esac

    # Include a touch of the target name so make can check
    # if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}
  done  # end for file in chapter05/*
}


#----------------------------#
chapter6_Makefiles() {
#----------------------------#

  # Set envars and scripts for iteration targets
  if [[ -z "$1" ]] ; then
    local N=""
  else
    local N=-build_$1
    local chapter6=""
    mkdir chapter06$N
    cp chapter06/* chapter06$N
    for script in chapter06$N/* ; do
      # Overwrite existing symlinks, files, and dirs
      sed -e 's/ln -sv/&f/g' \
          -e 's/mv -v/&f/g' \
          -e 's/mkdir -v/&p/g' -i ${script}
      # Rename the scripts
      mv ${script} ${script}$N
    done
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter6$N     ( CHROOT ) ${R_arrow}"

  for file in chapter06$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # We'll run the chroot commands differently than the others, so skip them in the
    # dependencies and target creation.
    # Skip also linux-headers in iterative builds.
    case "${this_script}" in
      *chroot)      continue ;;
      *stripping*) [[ "${STRIP}" = "n" ]] && continue ;;
      *linux-headers*) [[ -n "$N" ]] && continue ;;
    esac

    # Grab the name of the package, if any.
    name=`grep "^PACKAGE=" ${file} | sed -e 's@PACKAGE=@@'`

    # Skip scripts not needed for iterations rebuilds
    if [[ "$name" = "" ]] && [[ -n "$N" ]] ; then
      case "${this_script}" in
        *stripping*) ;;
        *)  continue ;;
      esac
    fi

    # Append each name of the script files to a list (this will become
    # the names of the targets in the Makefile)
    # The kernfs script must be run as part of SUDO target.
    case "${this_script}" in
      *kernfs) runasroot="$runasroot ${this_script}" ;;
            *) chapter6="$chapter6 ${this_script}" ;;
    esac

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    # In the mount of kernel filesystems we need to set LFS
    # and not to use chroot.
    case "${this_script}" in
      *kernfs)  LUSER_wrt_target  "${this_script}" "$PREV" ;;
      *)        CHROOT_wrt_target "${this_script}" "$PREV" ;;
    esac

    # Touch timestamp file if installed files logs will be created.
    # But only for the firt build when running iterative builds.
    if [ "$name" != "" ] && [ "${INSTALL_LOG}" = "y" ] && [ "x${N}" = "x" ] ; then
      CHROOT_wrt_TouchTimestamp
    fi

    # In the mount of kernel filesystems we need to set LFS
    # and not to use chroot.
    case "${this_script}" in
      *kernfs)  wrt_RunAsRoot  "$file" ;;
      *)        CHROOT_wrt_RunAsRoot "$file" ;;
    esac

    # Write installed files log
    if [ "$name" != "" ] && [ "${INSTALL_LOG}" = "y" ] && [ "x${N}" = "x" ] ; then
      CHROOT_wrt_LogNewFiles "$name"
    fi

    # Include a touch of the target name so make can check
    # if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}
    # Set system_build envar for iteration targets
    system_build=$chapter6
  done # end for file in chapter06/*
}

#----------------------------#
chapter78_Makefiles() {
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter7/8   ( BOOT ) ${R_arrow}"

  for file in chapter0{7,8}/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Grub must be configured manually.
    # Handle fstab creation.
    # If no .config file is supplied, the kernel build is skipped
    case ${this_script} in
      *grub)    continue ;;
      *fstab)   [[ ! -z ${FSTAB} ]] && cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *kernel)  [[ -z ${CONFIG} ]] && continue
                cp ${CONFIG} $BUILDDIR/sources/kernel-config  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter78="$chapter78 ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"

    # For bootscripts and kernel, start INSTALL_LOG if requested
    case "${this_script}" in
      *bootscripts | *kernel ) if [ "${INSTALL_LOG}" = "y" ] ; then
                                  CHROOT_wrt_TouchTimestamp
                                fi ;;
    esac

      # Check if we have a real /etc/fstab file
    case "${this_script}" in
      *fstab) if [[ -n $FSTAB ]]; then
                CHROOT_wrt_CopyFstab
              else
                CHROOT_wrt_RunAsRoot "$file"
              fi
        ;;
      *)        CHROOT_wrt_RunAsRoot "$file"
        ;;
    esac

    case "${this_script}" in
      *bootscripts)  if [ "${INSTALL_LOG}" = "y" ] ; then
                       CHROOT_wrt_LogNewFiles "lfs-bootscripts"
                     fi ;;
      *kernel)       if [ "${INSTALL_LOG}" = "y" ] ; then
                       CHROOT_wrt_LogNewFiles "linux"
                     fi ;;
    esac

    # Include a touch of the target name so make can check
    # if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}
  done  # for file in chapter0{7,8}/*

}



#----------------------------#
build_Makefile() {           #
#----------------------------#

  echo "Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands

  # Start with a clean Makefile.tmp file
  >$MKFILE

  chapter4_Makefiles
  chapter5_Makefiles
  chapter6_Makefiles
  # Add the iterations targets, if needed
  [[ "$COMPARE" = "y" ]] && wrt_compare_targets
  chapter78_Makefiles
  # Add the CUSTOM_TOOLS targets, if needed
  [[ "$CUSTOM_TOOLS" = "y" ]] && wrt_CustomTools_target
  # Add the BLFS_TOOL targets, if needed
  [[ "$BLFS_TOOL" = "y" ]] && wrt_blfs_tool_targets

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
  wrt_Makefile_header

  # Add chroot commands
  CHROOT_LOC="`whereis -b chroot | cut -d " " -f2`"
  i=1
  for file in chapter06/*chroot* ; do
    chroot=`cat $file | tr -d '\n' | \
            sed -e "s@chroot@$CHROOT_LOC@" \
                -e 's@ \\\@ @g' \
                -e 's/  */ /g' \
                -e 's|\\$|&&|g' \
                -e 's|"$$LFS"|$(MOUNT_PT)|' \
                -e 's|$| -c|'`
    echo -e "CHROOT$i= $chroot\n" >> $MKFILE
    i=`expr $i + 1`
  done

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
    cat << EOF

all:	ck_UID mk_SETUP mk_LUSER mk_SUDO mk_CHROOT mk_BOOT create-sbu_du-report mk_CUSTOM_TOOLS mk_BLFS_TOOL
	@sudo make do_housekeeping
	@echo "$VERSION - jhalfs build" > lfs-release && \\
	sudo mv lfs-release \$(MOUNT_PT)/etc
	@\$(call echo_finished,$VERSION)

ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "--------------------------------------------------"; \\
	  echo "You cannot run this makefile from the root account"; \\
	  echo "--------------------------------------------------"; \\
	  exit 1; \\
	fi

mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make BREAKPOINT=\$(BREAKPOINT) SETUP
	@touch \$@

mk_LUSER: mk_SETUP
	@\$(call echo_SULUSER_request)
	@( sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) LUSER" )
	@sudo make restore-luser-env
	@touch \$@

mk_SUDO: mk_LUSER
	@sudo make BREAKPOINT=\$(BREAKPOINT) SUDO
	@touch \$@

mk_CHROOT: mk_SUDO
	@\$(call echo_CHROOT_request)
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) CHROOT")
	@touch \$@

mk_BOOT: mk_CHROOT
	@\$(call echo_CHROOT_request)
	@( sudo \$(CHROOT2) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) BOOT")
	@touch \$@

mk_CUSTOM_TOOLS: create-sbu_du-report
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building CUSTOM_TOOLS); \\
	  sudo mkdir -p ${BUILDDIR}${TRACKING_DIR}; \\
	  (sudo \$(CHROOT2) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) CUSTOM_TOOLS"); \\
	fi;
	@touch \$@

mk_BLFS_TOOL: mk_CUSTOM_TOOLS
	@if [ "\$(ADD_BLFS_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building BLFS_TOOL); \\
	  sudo mkdir -p $BUILDDIR$TRACKING_DIR; \\
	  (sudo \$(CHROOT2) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) BLFS_TOOL"); \\
	fi;
	@touch \$@


SETUP:        $chapter4
LUSER:        $chapter5
SUDO:         $runasroot
CHROOT:       SHELL=/tools/bin/bash
CHROOT:       $chapter6
BOOT:         $chapter78
CUSTOM_TOOLS: $custom_list
BLFS_TOOL:    $blfs_tool


create-sbu_du-report:  mk_BOOT
	@\$(call echo_message, Building)
	@if [ "\$(ADD_REPORT)" = "y" ]; then \\
	  ./create-sbu_du-report.sh logs $VERSION; \\
	  \$(call echo_report,$VERSION-SBU_DU-$(date --iso-8601).report); \\
	fi;
	@touch  \$@

restore-luser-env:
	@\$(call echo_message, Building)
	@if [ -f \$(LUSER_HOME)/.bashrc.XXX ]; then \\
		mv -f \$(LUSER_HOME)/.bashrc.XXX \$(LUSER_HOME)/.bashrc; \\
	fi;
	@if [ -f \$(LUSER_HOME)/.bash_profile.XXX ]; then \\
		mv \$(LUSER_HOME)/.bash_profile.XXX \$(LUSER_HOME)/.bash_profile; \\
	fi;
	@chown \$(LUSER):\$(LGROUP) \$(LUSER_HOME)/.bash*
	@\$(call housekeeping)

do_housekeeping:
	@-umount \$(MOUNT_PT)/sys
	@-umount \$(MOUNT_PT)/proc
	@-umount \$(MOUNT_PT)/dev/shm
	@-umount \$(MOUNT_PT)/dev/pts
	@-umount \$(MOUNT_PT)/dev
	@-rm /tools
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf \$(LUSER_HOME); \\
	fi;


EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"
}
