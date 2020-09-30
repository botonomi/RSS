#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1

export ORGS=$(echo "$1" | tr ',' ' ' | tr ' ' '|') #FIXME
export LANGUAGES=$(echo "$2" | tr ',' '|')
export LABELS=$(echo "$3" | tr ',' '|')


export LABELS="Help Wanted|Hacktoberfest"
# Should this be an argument?
CUTOFFDATE=12096000

printf '\e[1;37m%-6s\e[m\n' "Collecting \"Help Wanted\" issues from repos in the following organizations:"
echo $1 | tr ',' "\n" | while read ORG
do
    printf '\e[1;37m%-6s\e[m\n' "* $ORG"
done

printf '\e[1;37m%-6s\e[m\n' "Filtering for languages:"
echo $2 | tr ',' "\n" | while read LANGUAGE
do
    printf '\e[1;37m%-6s\e[m\n' "* $LANGUAGE"
done

REPO_OWNER=$GITHUB_ACTOR
REPO_NAME=$(basename $(pwd))
RSS_FEED_URL="https://$GITHUB_ACTOR.github.io/$REPO_NAME/feed.xml"


for ORG in $ORGS
do
    STOP=$(curl -v -u :$TOKEN "https://api.github.com/users/$ORG/repos" -o /dev/null 2>&1 | tr [:punct:] ' ' | awk '/next/ { print $21 }')

    for PAGE in $(seq 1 $STOP)
    do
    
        echo "TICKLE: https://api.github.com/users/$ORG/repos?page=$PAGE"

        curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq .[]

    done
done
