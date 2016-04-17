#!/bin/bash

#
# CIS Debian 7 Hardening
# Authors : Thibault Dewailly, OVH <thibault.dewailly@corp.ovh.com>
#

#
# 13.13 Check User Home Directory Ownership (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

ERRORS=0

# This function will be called if the script status is on enabled / audit mode
audit () {

    cat /etc/passwd | awk -F: '{ print $1 " " $3 " " $6 }' | while read USER USERID DIR; do
        if [ $USERID -ge 500 -a -d "$DIR" -a $USER != "nfsnobody" ]; then
            OWNER=$(stat -L -c "%U" "$DIR")
            if [ "$OWNER" != "$USER" ]; then
                crit "The home directory ($DIR) of user $USER is owned by $OWNER."
                ERRORS=$(($ERRORS+1))
            fi
        fi
    done

    if [ $ERRORS = 0 ]; then
        ok "All home directories have correct ownership"
    fi 
}

# This function will be called if the script status is on enabled mode
apply () {
    cat /etc/passwd | awk -F: '{ print $1 " " $3 " " $6 }' | while read USER USERID DIR; do
        if [ $USERID -ge 500 -a -d "$DIR" -a $USER != "nfsnobody" ]; then
            OWNER=$(stat -L -c "%U" "$DIR")
            if [ "$OWNER" != "$USER" ]; then
                warn "The home directory ($DIR) of user $USER is owned by $OWNER."
                chown $USER $DIR
            fi
        fi
    done
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ ! -r /etc/default/cis-hardenning ]; then
    echo "There is no /etc/default/cis-hardenning FILE, cannot source CIS_ROOT_DIR variable, aborting"
    exit 128
else
    . /etc/default/cis-hardenning
    if [ -z $CIS_ROOT_DIR ]; then
        echo "No CIS_ROOT_DIR variable, aborting"
    fi
fi 

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
[ -r $CIS_ROOT_DIR/lib/main.sh ] && . $CIS_ROOT_DIR/lib/main.sh
