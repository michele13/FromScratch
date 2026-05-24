(./*.md)
(/*/.md)
(/*.md)

[link](./page.md)
[doc](./doc/page.md)
[foo](/foo/page.md)
[external-ssl](https://example.com/index.md)
[external](http://example.com/index.md)

sed 's@\./@g'

\([\./]*


Can you write a regular expression that allows me to changes this:

[link](./page.md)
[doc](./doc/page.md)
[foo](/foo/page.md)

to this?

[link](./page.html)
[doc](./doc/page.html)
[foo](/foo/page.html)

sed '\(\.?/[a-zA-Z-0-9_-]*\.

(\(\.?/[a-zA-Z-0-9_-]*/?)(\.md)

https://www.freecodecamp.org/news/content/images/2023/07/exact_match.png

1. trova ogni pattern che contiene "(./" o "(/"
2. sostituisci ogni occorrenza di ".md" con ".html"

sed -E '@\((\.|/)@s@\.md@\.html@g'


FINAL SED COMMAND

sed -E '/\((\.|\/)/ s@\.md@\.html@g'

MIX IT WITH PANDOC

sed -E '/\((\.|\/)/ s@\.md@\.html@g' | pandoc -f markdown -t html5 -s -c style.css