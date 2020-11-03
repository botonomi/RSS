#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1

export ORGS=$(echo "$1" | tr ',' ' ' | tr '|' ' ') #FIXME
export LANGUAGES=$(echo "$2" | tr ',' '|')
export LABELS=$(echo "$3" | tr ',' '|')


export LABELS="Help Wanted|Up For Grabs"
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
            curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq '.[] | "\(.open_issues) \(.full_name)"' | awk '$1 != "\"0" { gsub(/"/, ""); print $NF }' | while read I
            do
                curl -s -u :$TOKEN "https://api.github.com/repos/$I/languages" | jq . | egrep -qi "$LANGUAGES" && (

                    for IPAGE in $(seq 1 5)
                    do
                        #                        
                        curl -s -u :$TOKEN "https://api.github.com/repos/$I/issues?page=$IPAGE" | jq '.[] | "\(.updated_at)¡\(.labels[].name)¡\(.title)¡\(.html_url)¡\(.number)"' | egrep -i "$LABELS" | while read RAW
                        do
                            THEN=$(date -d $(echo "$RAW" | awk -F"¡" '{ gsub(/"/, ""); print $1 }'| awk -F"T" '{ print $1 }') +%s )
                            DIFF=$(($(date +%s)-$THEN))

                            if [[ $DIFF -ge $CUTOFFDATE ]]
                            then
                              true
                            else
                                LABELS=$(echo   "$RAW" | awk -F"¡" '{ print $2 }')
                                TITLE=$(echo    "$RAW" | awk -F"¡" '{ print $3 }' | sed -e 's/</\&lt;/g' | sed -e 's/>/\&gt;/g' | sed -e 's/\&/\&amp;/g' | sed -e 's/%/%%/g')
                                URL=$(echo      "$RAW" | awk -F"¡" '{ print $4 }')
                                ID=$(echo       "$RAW" | awk -F"¡" '{ print $5 }')  
                            
                                # Feeler: is there a PR open for this?
                                #PRed=$(curl -s -u :$TOKEN "https://github.com/pulls?q=is%3Apr+user%3A"$ORG"+%23"$ID | jq .total_count)
                        
                                BODY=$(curl -s -u :$TOKEN "https://api.github.com/repos/$I/issues/$ID" | jq .body| sed -e 's/^"//' | sed -e 's/"$//'| xargs -0 printf | pandoc --wrap=preserve)
                        
                                #if [[ "$PRed" -gt "0" ]]
                                #then
                                #    printf "<item>\n<title>$TITLE</title>\n\t<link>$URL</link>\n\t<description><![CDATA[ <h3 style=\"background-color:yellow\">$PRed PRs opened</h3><pre>$BODY</pre> ]]></description>\n</item>\n" | awk '{ gsub("\014","\\f"); gsub("\010","\\b"); print }'
                                #else
                                    printf "<item>\t<title>$TITLE</title>\n\t<link>$URL</link>\n\t<description><![CDATA[ <pre>$BODY</pre> ]]></description>\n</item>\n" | awk '{ gsub("\014","\\f"); gsub("\010","\\b"); print }'
                                #fi
                            fi
                        done
                    #
                    done
                )
            done
        done
    done
    printf "\n</channel>\n</rss>\n"
) | base64 | tr -d "\n" > feed.xml

# Harvest current SHA of feed.xml
CURRENT_SHA=$(curl -L -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml | jq .sha | tr -d '"' | head -1)

# Publish new feed.xml
curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml | jq .content.html_url

# Push page
curl -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/pages | jq .html_url | grep -q "$GITHUB_REPOSITORY" || curl -s -u :$TOKEN -X POST -H "Accept: application/vnd.github.switcheroo-preview+json" https://api.github.com/repos/$GITHUB_REPOSITORY/pages
