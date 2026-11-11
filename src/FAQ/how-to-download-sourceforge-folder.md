# Download Sourceforge Folder

**Source:** https://stackoverflow.com/questions/39668291/download-whole-folder-from-sourceforge

In every Sourceforge project or project folders page there is an RSS link, as you can see in the example screenshot here [1].

right click that RSS icon in the page of the folder or project you want to download then copy the link and use the following Bash script:

```shell
curl "<URL>" | grep "<link>.*</link>" | sed 's|<link>||;s|</link>||' | while read url; do url=`echo $url | sed 's|/download$||'`; wget $url ; done
```

replace "<URL>" with your RSS link for example : "https://sourceforge.net/projects/xdxf/rss?path=/dicts-babylon/001", and watch the magic happens, The RSS link will include all the files of the Sourceforge folder or project and it's sub-folders, so the script will download everything recursively.

If the above script doesn't work, try this one that extracts the links from the HTML directly, Replace "<URL>" with the project's files URL example : "https://sourceforge.net/projects/synwrite-addons/files/Lexers/"

```shell
curl "<URL>" | tr '"' "\n" | grep "sourceforge.net/projects/.*/download"  | sort  | uniq | while read url; do url=`echo $url | sed 's|/download$||'`; wget $url ; done
```

Good luck

[1]: https://i.sstatic.net/fqsnH.jpg