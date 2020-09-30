#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1

export ORGS=$(echo "$1" | tr -d ' ' | tr ' ' '|') #FIXME
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

(
    # RSS Boilerplate
    #

    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo '<rss version="2.0">'
    printf "<channel>\n<title>Help Wanted</title>\n<description>Help Wanted Issues</description>\n<link>$RSS_FEED_URL</link>\n"

for ORG in $ORGS
do
    STOP=$(curl -v -u :$TOKEN "https://api.github.com/users/$ORG/repos" -o /dev/null 2>&1 | tr [:punct:] ' ' | awk '/next/ { print $21 }')

    for PAGE in $(seq 1 $STOP)
    do

        curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq .[]

    done

    printf "\n</channel>\n</rss>\n"
) | base64 | tr -d "\n" > feed.xml

# Harvest current SHA of feed.xml
CURRENT_SHA=$(curl -L -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml | jq .sha | tr -d '"' | head -1)

# Publish new feed.xml
curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml | jq .content.html_url

# Push page
curl -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/pages | jq .html_url | grep -q "$GITHUB_REPOSITORY" || curl -s -u :$TOKEN -X POST -H "Accept: application/vnd.github.switcheroo-preview+json" https://api.github.com/repos/$GITHUB_REPOSITORY/pages
