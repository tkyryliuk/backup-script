#!/bin/bash

#Website Backup Script

#Find current path
CURRENT_PATH=`pwd`

while
    read -a STRING_ARRAY;
do
    PROJECT_NAME=${STRING_ARRAY[0]};
    SOURCE_DIR=${STRING_ARRAY[1]};
    SSH_PORT=${STRING_ARRAY[2]};

    echo "Current job: $PROJECT_NAME";

    #Todays date in ISO-8601 format:
    DATE=`date "+%Y-%m-%d_%H-%M-%S"`

    #Last backup name:
    #create project folder if it doesn't exists
    if [ ! -e "backups/$PROJECT_NAME/last_backupname" ]; then
        mkdir backups/"$PROJECT_NAME"
        touch backups/"$PROJECT_NAME"/last_backupname
        echo "0" > backups/"$PROJECT_NAME"/last_backupname
    fi

    read LAST_BACKUP < backups/"$PROJECT_NAME"/last_backupname

    #The target directory:
    TARGET_DIR="$CURRENT_PATH/backups/"$PROJECT_NAME"/$DATE"

    #The link destination directory:
    LNK_DEST="$CURRENT_PATH/backups/"$PROJECT_NAME"/$LAST_BACKUP"

    #The rsync options:
    SSH_KEY="/home/taras/.ssh/id_rsa"
    SSH_OPT="ssh -o ConnectTimeout=60 -p $SSH_PORT -i $SSH_KEY"
    RSYNC_OPT="-avh --delete --link-dest=$LNK_DEST"

    #Execute the backup
    TRIES=0
    while [ 1 ]
    do
        rsync $RSYNC_OPT -e "$SSH_OPT" $SOURCE_DIR $TARGET_DIR
        if [ "$?" = "0" ] ; then
            echo "$DATE $PROJECT_NAME rsync completed normally" >> success.log
            #write backup name into file for the next execution
            echo $DATE > backups/"$PROJECT_NAME"/last_backupname
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
