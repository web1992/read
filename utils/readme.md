# utils

```shell
    # 生成文件的目录index
    cat spring-reference-022.md |grep ^# | awk -F"## " '{ print $2}' |grep -v '^$' |sed 's/ [ ]*/-/g' |sed 's/[@]//g' |sed 's/(//g'|sed 's/)//g' | tr '[a-zA-Z]' '[a-za-z]'| awk '$0="- "NR" ["$0"](#"$0")"'
```