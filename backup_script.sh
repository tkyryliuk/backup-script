#!/bin/bash

#Website Backup Script

#include file with settings
. settings

#Find current path
CURRENT_PATH=`pwd`

while
    #read from file projects_list by line
    read -a STRING_ARRAY;
do
    PROJECT_NAME=${STRING_ARRAY[0]};
    SOURCE_DIR=${STRING_ARRAY[1]};
    SSH_PORT=${STRING_ARRAY[2]};
    FREQUENCY=${STRING_ARRAY[3]};
    
    echo "Current job: $PROJECT_NAME";

    #Date vars in ISO-8601 format:
    DATE_TIME=`date "+%Y-%m-%d_%H-%M-%S"`
    YEAR=`date "+%Y"`
    MONTH=`date "+%m"`
    WEEK=`date "+%W"`
    DAY=`date "+%d"`

    #create project folder if it doesn't exists
    if [ ! -e "backups/$PROJECT_NAME/last_backupname" ]; then
        #create project folder
        mkdir backups/"$PROJECT_NAME"
        touch backups/"$PROJECT_NAME"/last_backupname
        echo "0" > backups/"$PROJECT_NAME"/last_backupname
        #create subfolders for backups
        mkdir backups/"$PROJECT_NAME"/01_Yearly
        mkdir backups/"$PROJECT_NAME"/02_Monthly
        mkdir backups/"$PROJECT_NAME"/03_Weekly
        mkdir backups/"$PROJECT_NAME"/04_Daily
        
    fi
    
    #Last backup name:
    read LAST_BACKUP < backups/"$PROJECT_NAME"/last_backupname
    
    #define where to put current backup
    if [ ! -d "backups/$PROJECT_NAME/01_Yearly/$YEAR" ]; then
        mkdir backups/"$PROJECT_NAME"/01_Yearly/"$YEAR"
        TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/01_Yearly/$YEAR/$DATE_TIME"
        BACKUP_NAME="01_Yearly/$YEAR/$DATE_TIME"
        
    elif [ ! -d "backups/$PROJECT_NAME/02_Monthly/$YEAR-$MONTH" ]; then
        mkdir backups/"$PROJECT_NAME"/02_Monthly/"$YEAR-$MONTH"
        TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/02_Monthly/$YEAR-$MONTH/$DATE_TIME"
        BACKUP_NAME="02_Monthly/$YEAR-$MONTH/$DATE_TIME"
        
    elif [ ! -d "backups/$PROJECT_NAME/03_Weekly/$YEAR-W$WEEK" ]; then
        #skip wekly/daily/hourly backups if we don't heed them
        if [ $FREQUENCY != "1w" ] && [ $FREQUENCY != "1d" ] && [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        mkdir backups/"$PROJECT_NAME"/03_Weekly/"$YEAR-W$WEEK"
        TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/03_Weekly/$YEAR-W$WEEK/$DATE_TIME"
        BACKUP_NAME="03_Weekly/$YEAR-W$WEEK/$DATE_TIME"
        
    elif [ ! -d "backups/$PROJECT_NAME/04_Daily/$YEAR-$MONTH-$DAY" ]; then
        #skip daily/hourly backups if we don't heed them
        if [ $FREQUENCY != "1d" ] && [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        mkdir backups/"$PROJECT_NAME"/04_Daily/"$YEAR-$MONTH-$DAY"
        TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        BACKUP_NAME="04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        
    else
        #skip hourly backups if we don't heed them
        if [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        #means this is hourly backup
        TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        BACKUP_NAME="04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
    fi
    
    #Link destination directory:
    LNK_DEST="$CURRENT_PATH/backups/"$PROJECT_NAME"/$LAST_BACKUP"

    #The rsync options:
    SSH_OPT="ssh -o ConnectTimeout=60 -p $SSH_PORT -i $SSH_KEY"
    RSYNC_OPT="-avh --delete --link-dest=$LNK_DEST"

    #Execute the backup
    TRIES=0
    while [ 1 ]
    do
        rsync $RSYNC_OPT -e "$SSH_OPT" $SOURCE_DIR $TARGET_DIR
        #checking the result of rsync
        if [ "$?" = "0" ] ; then
            echo "$DATE $PROJECT_NAME rsync completed normally" >> success.log
            #write backup name into file for the next execution
            echo $BACKUP_NAME > backups/"$PROJECT_NAME"/last_backupname
            break
        else
            #if script tries less than 5 it will run again
            if [[ $TRIES -eq 5 ]] ; then
                echo "$DATE $PROJECT_NAME rsync failure. Skipping this job" >> error.log
                break
            fi
            let TRIES=TRIES+1
            echo "$DATE $PROJECT_NAME rsync failure. Backing off and retrying..."
            sleep 60
        fi
    done
done < ./projects_list
