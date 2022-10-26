# ES script

- sort script
- script_fields


> sort script

```json
"sort": [
    {
      "_script": {
        "script": {
          "source": "if(doc['orgId'].value ==params.curOrgId ){return doc['unitPrice'].value;} return doc['orgId'].value + params.changePrice",
          "lang": "painless",
          "params": {
            "changePrice": 5,
            "curOrgId":1000
          }
        },
        "type": "number",
        "order": "asc"
      }
    }
  ]
```

## Links

- https://www.elastic.co/guide/en/elasticsearch/reference/8.5/modules-scripting-using.html
- https://www.elastic.co/guide/en/elasticsearch/reference/8.5/scripts-and-search-speed.html