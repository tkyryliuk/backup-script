#!/bin/bash

#include file with settings
. settings

#The rsync options:
SSH_OPT="ssh -p $SSH_PORT -i $SSH_KEY"
RSYNC_OPT="-avh --delete"

#Restore the backup
rsync $RSYNC_OPT -e "$SSH_OPT" $SOURCE_DIR $TARGET_DIR
