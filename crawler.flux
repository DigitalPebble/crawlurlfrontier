name: "crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.urlfrontier.Spout"
    parallelism: 3

bolts:
  - id: "partitioner"
    className: "com.digitalpebble.stormcrawler.bolt.URLPartitionerBolt"
    parallelism: 3
  - id: "fetcher"
    className: "com.digitalpebble.stormcrawler.bolt.FetcherBolt"
    parallelism: 6
  - id: "sitemap"
    className: "com.digitalpebble.stormcrawler.bolt.SiteMapParserBolt"
    parallelism: 6
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 12
  - id: "shunt"
    className: "com.digitalpebble.stormcrawler.tika.RedirectionBolt"
    parallelism: 12
  - id: "tika"
    className: "com.digitalpebble.stormcrawler.tika.ParserBolt"
    parallelism: 12
  - id: "index"
    className: "com.digitalpebble.stormcrawler.indexing.DummyIndexer"
    parallelism: 6
  - id: "status"
    className: "com.digitalpebble.stormcrawler.urlfrontier.StatusUpdaterBolt"
    parallelism: 3

streams:
  - from: "spout"
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
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "sitemap"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "parse"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "tika"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "status"

