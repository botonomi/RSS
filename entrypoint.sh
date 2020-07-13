#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1

ORGS=$(echo "$1" | tr -d ' ' | tr ' ' '|')
LANGUAGES=$(echo "$2" | tr -d ' ' | tr ' ' '|')

# Should this be an argument?
CUTOFFDATE=1209600

printf '\e[1;37m%-6s\e[m\n' "Collecting \"Help Wanted\" issues from repos in the following organizations:"
echo $1 | tr ',' | while read ORG
do
    printf '\e[1;37m%-6s\e[m\n' "* $ORG"
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
        #Plumb
        STOP=$(curl -k -v -u :$TOKEN "https://api.github.com/users/$ORG/repos" -o /dev/null 2>&1 | tr [:punct:] ' ' | awk '/next/ { print $21 }')

        for PAGE in $(seq 1 $STOP)
        do
            # Reduce to repositories with issues
            curl -k -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq '.[] | "\(.open_issues) \(.full_name)"' | tr -d '"' | awk '$1 > 0 { print $2}' | while read ISSUED
            do
                # Only tell me about repos that contain languages I use
                curl -k -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/languages" | jq . | egrep -qi "$LANGUAGES" && (
                    curl -k -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/issues" |\
                      jq '.[] | "\(.updated_at)¡\(.labels[].name)¡\(.title)¡\(.html_url)¡\(.body)"' | awk -F"¡" '/help wanted/ { gsub(/[\"|\-|T|:|Z]/, " ", $1); if ((systime()-"'$CUTOFFDATE'")<mktime($1)) print $3"¡"$4"¡"$5 }' |\
                      awk -F"¡" '{ gsub(/\\n/, "<br\/>", $3); print "<item>\n\t<title>"$1"</title>\n\t<link>"$2"</link>\n\t<description><![CDATA["$3" ]]></description>\n</item>\n" }' 2>/dev/null | perl -e 'while(<>){$_=~s/\\r//g;print}'
                )
            done
        done
    done

    printf "\n</channel>\n</rss>\n"
) | sed -e 's/&/&amp;/g' | perl -le 'while (<>) {chomp; $bfr.=$_;} $bfr =~ s/\)/\)\n/g; foreach $f (split(/\n/, $bfr)){ if ($f =~ /(.*)\[(.*?)\]\((.*?)\)(.*?)/) { print "$1 <a href=\"$3\">$2</a> $4\n"; } else { print $f; }}' | base64 | tr -d "\n" > feed.xml

echo "Scrape https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml"

# Harvest current SHA of feed.xml
CURRENT_SHA=$(curl -L -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml | jq .sha | tr -d '"' | head -1)

curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$GITHUB_REPOSITORY/contents/feed.xml
