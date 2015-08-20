#!/bin/bash

#Find current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#include file with settings
. "$CURRENT_PATH"/settings

for d in $CURRENT_PATH/backups/*/ ; do
    
    #clean 01_Yearly directory
    cd $d/01_Yearly/
    (ls -t|head -n "$YEARLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 02_Monthly directory
    cd $d/02_Monthly/
    (ls -t|head -n "$MONTHLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 03_Weekly directory
    cd $d/03_Weekly/
    (ls -t|head -n "$WEEKLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 04_Daily directory
    cd $d/04_Daily/
    (ls -t|head -n "$DAILY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
done
