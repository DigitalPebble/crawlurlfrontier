ESHOST="http://localhost:9200"
ESCREDENTIALS="-u elastic:passwordhere"

curl $ESCREDENTIALS -s -XDELETE "$ESHOST/metrics*/" >  /dev/null

echo ""
echo "Deleted metrics index"

curl $ESCREDENTIALS -s -XPUT $ESHOST/_ilm/policy/7d-deletion_policy -H 'Content-Type:application/json' -d '
{
    "policy": {
        "phases": {
            "delete": {
                "min_age": "7d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}
'

echo "Creating metrics index with mapping"

# http://localhost:9200/metrics/_mapping/status?pretty
curl $ESCREDENTIALS -s -XPOST $ESHOST/_template/storm-metrics-template -H 'Content-Type: application/json' -d '
{
  "index_patterns": "metrics*",
  "settings": {
    "index": {
      "number_of_shards": 1,
      "refresh_interval": "30s"
    },
    "number_of_replicas": 0,
    "lifecycle.name": "7d-deletion_policy"
  },
  "mappings": {
      "_source":         { "enabled": true },
      "properties": {
          "name": {
            "type": "keyword"
          },
          "stormId": {
            "type": "keyword"
          },
          "srcComponentId": {
            "type": "keyword"
          },
          "srcTaskId": {
            "type": "short"
          },
          "srcWorkerHost": {
            "type": "keyword"
          },
          "srcWorkerPort": {
            "type": "integer"
          },
          "timestamp": {
            "type": "date",
            "format": "date_optional_time"
          },
          "value": {
            "type": "double"
          }
      }
  }
}'

curl $ESCREDENTIALS -X PUT $ESHOST/metrics


