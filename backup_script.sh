#!/bin/bash

#Website Backup Script

#define backup function
run_backup_job () {
    if [[ -z ${1+x} || -z ${2+x} || -z ${3+x} ]]; then
        echo "Error! Invalid paremeters received. Can't do this job.";
        exit
    fi

    #Find current path
    CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

    #include file with settings
    . "$CURRENT_PATH"/settings

    #defining required variables
    PROJECT_NAME=$1
    SOURCE_DIR=$2
    SSH_PORT=$3

    #if $FREQUENCY not set
    if [ -z "$4" ]; then
        FREQUENCY="1h"
    else
        FREQUENCY=$4
    fi

    #Date vars in ISO-8601 format:
    DATE_TIME=`date "+%Y-%m-%d_%H-%M-%S"`
    YEAR=`date "+%Y"`
    MONTH=`date "+%m"`
    WEEK=`date "+%W"`
    DAY=`date "+%d"`

    echo "Current job: backup $PROJECT_NAME";

    #create project folder if it doesn't exists
    if [ ! -e "$CURRENT_PATH/backups/$PROJECT_NAME/last_backupname" ]; then
        #create project folder
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME"
        touch "$CURRENT_PATH/backups/$PROJECT_NAME/last_backupname"
        echo "0" > "$CURRENT_PATH/backups/$PROJECT_NAME/last_backupname"
        #create subfolders for backups
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/01_Yearly"
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/02_Monthly"
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/03_Weekly"
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/04_Daily"
        
    fi

    #Last backup name:
    read LAST_BACKUP < "$CURRENT_PATH/backups/$PROJECT_NAME/last_backupname"
    
    #define where to put current backup
    if [ ! -d "$CURRENT_PATH/backups/$PROJECT_NAME/01_Yearly/$YEAR" ]; then
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/01_Yearly/$YEAR"
        TARGET_DIR="$CURRENT_PATH/backups/$PROJECT_NAME/01_Yearly/$YEAR/$DATE_TIME"
        BACKUP_NAME="01_Yearly/$YEAR/$DATE_TIME"
        
    elif [ ! -d "$CURRENT_PATH/backups/$PROJECT_NAME/02_Monthly/$YEAR-$MONTH" ]; then
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/02_Monthly/$YEAR-$MONTH"
        TARGET_DIR="$CURRENT_PATH/backups/$PROJECT_NAME/02_Monthly/$YEAR-$MONTH/$DATE_TIME"
        BACKUP_NAME="02_Monthly/$YEAR-$MONTH/$DATE_TIME"
        
    elif [ ! -d "$CURRENT_PATH/backups/$PROJECT_NAME/03_Weekly/$YEAR-W$WEEK" ]; then
        #skip wekly/daily/hourly backups if we don't heed them
        if [ $FREQUENCY != "1w" ] && [ $FREQUENCY != "1d" ] && [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/03_Weekly/$YEAR-W$WEEK"
        TARGET_DIR="$CURRENT_PATH/backups/$PROJECT_NAME/03_Weekly/$YEAR-W$WEEK/$DATE_TIME"
        BACKUP_NAME="03_Weekly/$YEAR-W$WEEK/$DATE_TIME"
        
    elif [ ! -d "$CURRENT_PATH/backups/$PROJECT_NAME/04_Daily/$YEAR-$MONTH-$DAY" ]; then
        #skip daily/hourly backups if we don't heed them
        if [ $FREQUENCY != "1d" ] && [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        mkdir "$CURRENT_PATH/backups/$PROJECT_NAME/04_Daily/$YEAR-$MONTH-$DAY"
        TARGET_DIR="$CURRENT_PATH/backups/$PROJECT_NAME/04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        BACKUP_NAME="04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        
    else
        #skip hourly backups if we don't heed them
        if [ $FREQUENCY != "1h" ]; then
            echo "Skiping this project..."
            continue
        fi
        #means this is hourly backup
        TARGET_DIR="$CURRENT_PATH/backups/$PROJECT_NAME/04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
        BACKUP_NAME="04_Daily/$YEAR-$MONTH-$DAY/$DATE_TIME"
    fi
    
    #Link destination directory:
    LNK_DEST="$CURRENT_PATH/backups/$PROJECT_NAME/$LAST_BACKUP"

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
            echo "$DATE_TIME $PROJECT_NAME rsync completed normally" >> "$CURRENT_PATH"/success.log
            #write backup name into file for the next execution
            echo $BACKUP_NAME > "$CURRENT_PATH"/backups/"$PROJECT_NAME"/last_backupname
            break
        else
            #if script tries less than 5 it will run again
            if [[ $TRIES -eq 5 ]] ; then
                echo "$DATE_TIME $PROJECT_NAME rsync failure. Skipping this job" >> "$CURRENT_PATH"/error.log
                break
            fi
            let TRIES=TRIES+1
            echo "$DATE_TIME $PROJECT_NAME rsync failure. Backing off and retrying..."
            sleep 60
        fi
    done
}


#Check is it one time job by checking if there any arguments passed to script
if [ -n "$1" ]; then
    #check if there are all required arguments
    if [[ -z ${2+x} || -z ${3+x} ]]; then
        echo "Error! Invalid paremeters received. Can't do this job.";
        exit
    fi

    PROJECT_NAME=$1
    SOURCE_DIR=$2
    SSH_PORT=$3

    #pass all arguments to the run_backup_job() function 
    run_backup_job $PROJECT_NAME $SOURCE_DIR $SSH_PORT
else
    #Find current path
    CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

    #if there are no passed arguments than do backups of all projects from projects_list file
    while
        read -a STRING_ARRAY;
    do
        PROJECT_NAME=${STRING_ARRAY[0]};
        SOURCE_DIR=${STRING_ARRAY[1]};
        SSH_PORT=${STRING_ARRAY[2]};
        FREQUENCY=${STRING_ARRAY[3]};

        run_backup_job $PROJECT_NAME $SOURCE_DIR $SSH_PORT $FREQUENCY

    done < "$CURRENT_PATH"/projects_list
fi
