name: "crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

    - resource: false
      file: "es-conf.yaml"
      override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.elasticsearch.persistence.AggregationSpout"
    parallelism: 10


bolts:
  - id: "partitioner"
    className: "com.digitalpebble.stormcrawler.bolt.URLPartitionerBolt"
    parallelism: 4
  - id: "custommetrics"
    className: "com.digitalpebble.stormcrawler.CustomMetricsReporterBolt"
    parallelism: 4    
  - id: "fetcher"
    className: "com.digitalpebble.stormcrawler.bolt.FetcherBolt"
    parallelism: 4
  - id: "sitemap"
    className: "com.digitalpebble.stormcrawler.bolt.SiteMapParserBolt"
    parallelism: 4
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 16
  - id: "shunt"
    className: "com.digitalpebble.stormcrawler.tika.RedirectionBolt"
    parallelism: 4 
  - id: "tika"
    className: "com.digitalpebble.stormcrawler.tika.ParserBolt"
    parallelism: 4
  - id: "index"
    className: "com.digitalpebble.stormcrawler.elasticsearch.bolt.IndexerBolt"
    parallelism: 4
  - id: "status"
    className: "com.digitalpebble.stormcrawler.elasticsearch.persistence.StatusUpdaterBolt"
    parallelism: 4
  - id: "deleter"
    className: "com.digitalpebble.stormcrawler.elasticsearch.bolt.DeletionBolt"
    parallelism: 4

streams:
  - from: "spout"
    to: "custommetrics"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "custommetrics"
    to: "partitioner"
    grouping:
      type: SHUFFLE

  - from: "partitioner"
    to: "fetcher"
    grouping:
      type: FIELDS
      args: ["key"]

  - from: "fetcher"
    to: "sitemap"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "sitemap"
    to: "parse"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "parse"
    to: "shunt"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "shunt"
    to: "tika"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "tika"

  - from: "tika"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "shunt"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "fetcher"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "sitemap"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "parse"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "tika"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "status"
    to: "deleter"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "deletion"
