# RSS

An [RSS feed](https://botonomi.github.io/RSS/feed.xml) of "Help Wanted" issues from [selected Github organizations](.github/workflows/RSS.yml#L28). 
Only repos that host code in a [defined language](.github/workflows/RSS.yml#L29) will be listed.

The human behind this repo uses [Slick RSS](https://github.com/hecktarzuli/slick-rss) to consume feeds through Chrome and Svyatoslav Vasilev's [RSS Reader](https://play.google.com/store/apps/details?id=com.madsvyat.simplerssreader&hl=en_US) for Android with much satisfaction.




## What's New:

2020-11-03 I seem to keep fixing and then obliterating handling of &lt;tags&gt; in the article CDATA, let's try again.  
2020-10-01 finally got Pandoc into the mix, articles now look like their issues. Hat-tip to [conoria](https://hub.docker.com/u/conoria) for the docker image!


<a href="https://validator.w3.org/feed/check.cgi?url=https%3A%2F%2Fbotonomi.github.io%2FRSS%2Ffeed.xml"><img src="https://validator.w3.org/feed/images/valid-rss-rogers.png" /></a>
