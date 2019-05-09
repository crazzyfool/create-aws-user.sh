#!/bin/bash
set -e
clear

NEW_USERS_FULL_NAME=""
NEW_USERS_USERNAME=""
NEW_USERS_PASSWORD=""
NEW_USERS_AWS_GROUP=""

sanitise_string() {
  echo ${1} | sed 's/[^ a-zA-Z0-9]//g' | awk '{print tolower($0)}'
}



if [ -z "$NEW_USERS_FULL_NAME" ]
then
  echo -e "What is the new users full name?\n"
  read FULL_NAME
  if [ $(echo $FULL_NAME | wc -w) -ne 2 ]
  then
    #clear
    echo -e "\nERROR: Please enter both first and second name!\n"
    exit 1
  else
    NEW_USERS_FULL_NAME="$FULL_NAME"
  fi
  echo -e "----------------------------------------------\n"
fi

if [ -z "$NEW_USERS_USERNAME" ]
then
  if [ ! -z "$NEW_USERS_FULL_NAME" ]
  then
    SUGGESTED_USERNAME=$(echo "$NEW_USERS_FULL_NAME" | head -c 1 && echo "$NEW_USERS_FULL_NAME" | awk '{print $2;}')
    echo -e "What username shall we use? We have generated the below username based on the users full name....\n"
    sanitise_string $SUGGESTED_USERNAME

    echo
    read -p "Do you want to use the above? Please confirm [y/n]" -n 1 
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      NEW_USERS_USERNAME=$(sanitise_string $SUGGESTED_USERNAME)
    else
      echo
      echo "What username shall we use?"
      echo
      read USERNAME
      NEW_USERS_USERNAME=$USERNAME
    fi
    echo -e "\n----------------------------------------------\n"
  fi
fi


if [ -z "$NEW_USERS_PASSWORD" ]
then
  NEW_USERS_PASSWORD=$(openssl rand -base64 14)
fi


if [ -z "$NEW_USERS_AWS_GROUP" ]
then
  echo -e "Please select a group:\n"
  array=( $(aws iam list-groups --output text | cut -f2 | cut -d '/' -f2) )

  # Make a dialog of choices
  select X in "${array[@]}"
  do
    # In this loop, X will be set to the file selected
    NEW_USERS_AWS_GROUP=$X
    break
  done
fi



create_user() {

  user=${1}
  password=${2}
  group=${3}

  aws iam create-user --user-name ${user}
  aws iam create-login-profile --user-name ${user} --password ${password} --password-reset-required
  aws iam add-user-to-group --user-name ${user} --group-name ${group}
}



print_user_details() {
  echo
  echo "User details"
  echo "============"
  echo -e "Users Full Name:\t $NEW_USERS_FULL_NAME"
  echo -e "Username:\t\t $NEW_USERS_USERNAME"
  echo -e "Password:\t\t $NEW_USERS_PASSWORD"
  echo -e "Group:\t\t\t $NEW_USERS_AWS_GROUP\n"
}

if [ ! -z "$NEW_USERS_PASSWORD" ] && [ ! -z "$NEW_USERS_USERNAME" ] && [ ! -z "$NEW_USERS_FULL_NAME" ] && [ ! -z "$NEW_USERS_AWS_GROUP" ]
then
  print_user_details
else
  echo -e "Error! Are you sure you entered the information in correctly?\n"
fi



read -p "Create AWS user with the above details? Please confirm [y/n]" -n 1
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
  #NEW_USERS_USERNAME=$(sanitise_string $SUGGESTED_USERNAME)
  echo
  echo -e "Creating user...\n"
  AWS_PROFILE=default create_user "$NEW_USERS_USERNAME" "$NEW_USERS_PASSWORD" "$NEW_USERS_AWS_GROUP"
  echo -e "\nUser successfully created!\n"
else
  echo
  echo -e "Don't create user!\n"
  exit 1
fi

