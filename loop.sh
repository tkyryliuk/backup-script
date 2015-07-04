#!/bin/bash
CURRENT_PATH=`pwd`
# echo "Curent path: $CURRENT_PATH"

while
    read -a STRING_ARRAY;
do
    PROJECT_NAME=${STRING_ARRAY[0]};
    SOURCE_DIR=${STRING_ARRAY[1]};
    SSH_PORT=${STRING_ARRAY[2]};
 
    # echo "Current job: $PROJECT_NAME $SOURCE_DIR $SSH_PORT";

    #Todays date in ISO-8601 format:
    DATE=`date "+%Y-%m-%d_%H-%M-%S"`

    # echo "$PROJECT_NAME";
    # echo "$SOURCE_DIR";
    # read LAST_UP < backups/"$PROJECT_NAME"/last_backupname
    # echo "$LAST_UP";

    # echo "$CURRENT_PATH/backups/"$PROJECT_NAME"/$DATE";

    if [ ! -e "backups/$PROJECT_NAME/last_backupname" ]; then
        mkdir backups/"$PROJECT_NAME"
        touch backups/"$PROJECT_NAME"/last_backupname
        echo "0" > backups/"$PROJECT_NAME"/last_backupname
    fi
    read LAST_BACKUP < backups/"$PROJECT_NAME"/last_backupname
    echo "$LAST_BACKUP";


done < ./projects_list