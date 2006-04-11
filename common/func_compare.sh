# $Id$

#----------------------------------#
wrt_compare_targets() {            #
#----------------------------------#

  for ((N=1; N <= ITERATIONS ; N++)) ; do # Double parentheses,
                                          # and "ITERATIONS" with no "$".
    ITERATION=iteration-$N
    if [ "$N" != "1" ] ; then
      wrt_system_build "$N"
    fi
    wrt_target "$ITERATION" "$PREV"
    wrt_compare_work "$ITERATION" "$PREV_IT"
    wrt_logs "$N"
    PREV_IT=$ITERATION
    PREV=$ITERATION
  done
}

#----------------------------------#
wrt_system_build() {               #
#----------------------------------#
  local RUN=$1

  # Placeholder for now

  echo "system_build_$N: $PREV $chapter6" >> $MKFILE.tmp
  PREV=system_build_$N
}

#----------------------------------#
wrt_compare_work() {               #
#----------------------------------#
  local ITERATION=$1
  local   PREV_IT=$2
  local PRUNEPATH="/dev /home /jhalfs /lost+found /media /mnt /opt /proc \
/sources /root /srv /sys /tmp /tools /usr/local /usr/src /var/log/paco"

  if [[ "$PROGNAME" = "clfs" ]] && [[ "$METHOD" = "boot" ]] ; then
    local    ROOT_DIR=/
    local DEST_TOPDIR=/jhalfs
    local   ICALOGDIR=/jhalfs/logs/ICA
    local FARCELOGDIR=/jhalfs/logs/farce
  else
    local    ROOT_DIR=$BUILDDIR
    local DEST_TOPDIR=$BUILDDIR/jhalfs
  fi

  if [[ "$RUN_ICA" = "1" ]] ; then
    local DEST_ICA=$DEST_TOPDIR/ICA && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_ICA/$ITERATION && \\
	extras/do_ica_prep $DEST_ICA/$ITERATION
EOF
) >> $MKFILE.tmp
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_ica_work "$PREV_IT" "$ITERATION" "$DEST_ICA"
    fi
  fi

  if [[ "$RUN_FARCE" = "1" ]] ; then
    local DEST_FARCE=$DEST_TOPDIR/farce && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_FARCE/$ITERATION && \\
	extras/filelist $DEST_FARCE/$ITERATION $DEST_FARCE/$ITERATION.filelist
EOF
) >> $MKFILE.tmp
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_farce_work "$PREV_IT" "$ITERATION" "$DEST_FARCE"
    fi
  fi
}

#----------------------------------#
wrt_do_ica_work() {                #
#----------------------------------#
  echo -e "\t@extras/do_ica_work $1 $2 $ICALOGDIR $3" >> $MKFILE.tmp
}

#----------------------------------#
wrt_do_farce_work() {              #
#----------------------------------#
  local OUTPUT=$FARCELOGDIR/${1}_V_${2}
  local PREDIR=$3/$1
  local PREFILE=$3/$1.filelist
  local ITEDIR=$3/$2
  local ITEFILE=$3/$2.filelist
  echo -e "\t@extras/farce --directory $OUTPUT $PREDIR $PREFILE $ITEDIR $ITEFILE" >> $MKFILE.tmp
}

#----------------------------------#
wrt_logs() {             #
#----------------------------------#
  local ITERATION=iteration$1

(
    cat << EOF
	@pushd logs && \\
	mkdir $ITERATION && \\
	cp ${chapter6}-$N $ITERATION && \\
	popd
	@touch \$@

EOF
) >> $MKFILE.tmp
}
