#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1

export ORGS=$(echo "$1" | tr ',' ' ' | tr '|' ' ') #FIXME
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
        curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq '.[] | "\(.open_issues) \(.full_name)"' | awk '$1 != "\"0" { gsub(/"/, ""); print $NF }' | while read I
        do
            curl -s -u :$TOKEN "https://api.github.com/repos/$I/languages" | jq . | egrep -qi "$LANGUAGES" && (
                curl -s -u :$TOKEN "https://api.github.com/repos/$I/issues" | jq '.[] | "\(.updated_at)¡\(.labels[].name)¡\(.title)¡\(.html_url)¡\(.body)"' | egrep -i "$LABELS" | while read RAW
                do
                    #echo "$RAW"
                        THEN=$(date -d $(echo "$RAW" | awk -F"¡" '{ gsub(/"/, ""); print $1 }') +%s )
                        echo "THEN: $THEN"
                        DIFF=$(($(date +%s)-$THEN))

                        if [[ $DIFF -ge $CUTOFFDATE ]]
                        then
                            true
                        else
                            LABELS=$(echo   "$RAW" | awk -F"¡" '{ print $2 }')
                            TITLE=$(echo    "$RAW" | awk -F"¡" '{ print $3 }')
                            URL=$(echo      "$RAW" | awk -F"¡" '{ print $4 }')
                            BODY=$(echo     "$RAW" | awk -F"¡" '{ print $5 }' | pandoc | sed -e 's/rn/<br>/g')
                            printf "<item>\t<title>$TITLE</title>\n\t<link>$URL</link>\n\t<description><![CDATA[ $BODY ]]></description>\n</item>\n"
                        fi
                done
            )
            done

    done
done
