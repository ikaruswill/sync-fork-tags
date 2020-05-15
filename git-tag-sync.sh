#!/usr/bin/env bash

# Required:
# WORKDIR
# REPO
# UPSTREAM
# SSH_KEY
echo "Configuring SSH..."
KNOWN_HOSTS_FILE='./known_hosts'
SSH_PRIVATE_KEY_FILE='./id_rsa'

SSH_PATH=$HOME/.ssh/
mkdir -p $SSH_PATH
cp $KNOWN_HOSTS_FILE $SSH_PATH
cp $SSH_PRIVATE_KEY_FILE $SSH_PATH

REPO='https://github.com/ikaruswill/gitea.git'
UPSTREAM='https://github.com/go-gitea/gitea.git'
REPO_PATH='/repo'

echo "Cloning repository..."
mkdir -p $REPO_PATH
git clone $REPO $REPO_PATH
cd $REPO_PATH
git remote add upstream $UPSTREAM

echo "Checking origin URL..."

REPO_URL=`git remote -v | grep -m1 '^origin' | sed -Ene's#.*(https://[^[:space:]]*).*#\1#p'`
if [ -z "$REPO_URL" ]; then
    echo "Repo origin is using SSH"
else
    echo "Repo origin is using HTTPS, converting to SSH..."
    USER=`echo $REPO_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\1#p'`
    if [ -z "$USER" ]; then
        echo "-- ERROR:  Could not identify User."
        exit
    fi

    REPO=`echo $REPO_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\2#p'`
    if [ -z "$REPO" ]; then
        echo "-- ERROR:  Could not identify Repo."
        exit
    fi

    NEW_URL="git@github.com:$USER/$REPO.git"
    echo "Changing repo url from "
    echo "  '$REPO_URL'"
    echo "      to "
    echo "  '$NEW_URL'"
    echo ""

    CHANGE_CMD="git remote set-url origin $NEW_URL"
    `$CHANGE_CMD`

    echo "Repo origin converted to SSH"
fi

echo "Fetching tags..."
TAGS=$(git fetch upstream --tags 2>&1 | sed -n 's/^.*\[new tag\].*->\s*\(.*\).*$/\1/p')

for tag in $TAGS; do
    echo "Pushing $tag..."
    git push origin $tag
done

echo "Done"