#!/bin/bash

#include file with settings
. settings

#Find current path
CURRENT_PATH=`pwd`

while
    read -a STRING_ARRAY;
do
    PROJECT_NAME=${STRING_ARRAY[0]};
    
    #clean 01_Yearly directory
    cd "$CURRENT_PATH"/backups/"$PROJECT_NAME"/01_Yearly/
    (ls -t|head -n "$YEARLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 02_Monthly directory
    cd "$CURRENT_PATH"/backups/"$PROJECT_NAME"/02_Monthly/
    (ls -t|head -n "$MONTHLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 03_Weekly directory
    cd "$CURRENT_PATH"/backups/"$PROJECT_NAME"/03_Weekly/
    (ls -t|head -n "$WEEKLY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
    #clean 04_Daily directory
    cd "$CURRENT_PATH"/backups/"$PROJECT_NAME"/04_Daily/
    (ls -t|head -n "$DAILY";ls)|sort|uniq -u|xargs --no-run-if-empty rm -rf
    
done < ./projects_list