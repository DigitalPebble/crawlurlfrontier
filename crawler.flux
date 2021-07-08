name: "crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

config:
  awscreds: { "fs.s3a.fast.upload.buffer": "array", "fs.s3a.multipart.size": "100M", "fs.s3a.multipart.purge": "true", "fs.s3a.multipart.purge.age": "86400", "fs.s3a.access.key": "XXXX", "fs.s3a.secret.key": "YYYY" }

components:
  - id: "WARCFileNameFormat"
    className: "com.digitalpebble.stormcrawler.warc.WARCFileNameFormat"
    configMethods:
      - name: "withPath"
        args:
          - ""
      - name: "withPrefix"
        args:
          - "1MTopHosts"

  - id: "WARCFileRotationPolicy"
    className: "org.apache.storm.hdfs.bolt.rotation.FileSizeRotationPolicy"
    constructorArgs:
      - 1000.0
      - MB

  - id: "WARCInfo"
    className: "java.util.LinkedHashMap"
    configMethods:
      - name: "put"
        args:
         - "software"
         - "StormCrawler 2.1 http://stormcrawler.net/"
      - name: "put"
        args:
         - "format"
         - "WARC File Format 1.0"
      - name: "put"
        args:
         - "conformsTo"
         - "https://iipc.github.io/warc-specifications/specifications/warc-format/warc-1.0/"
      - name: "put"
        args:
         - "description"
         - "Crawl of the top 1M hostnames according to CommonCrawl's webgraphs with StormCrawler and URLFrontier"

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.urlfrontier.Spout"
    parallelism: 4

#  - id: "filespout"
#    className: "com.digitalpebble.stormcrawler.spout.FileSpout"
#    parallelism: 1
#    constructorArgs:
#      - "."
#      - "top1M.hosts.commoncrawl"
#      - true

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
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 16
  - id: "warc"
    className: "com.digitalpebble.stormcrawler.warc.WARCHdfsBolt"
    parallelism: 4
    configMethods:
      - name: "withFileNameFormat"
        args:
          - ref: "WARCFileNameFormat"
      - name: "withRotationPolicy"
        args:
          - ref: "WARCFileRotationPolicy"
      - name: "withRequestRecords"
      - name: "withHeader"
        args:
          - ref: "WARCInfo"
      - name: "withConfigKey"
        args:
          - "awscreds"
      - name: "withFsUrl"
        args:
          - "s3a://commoncrawl-temp-eu-west-3/"
  - id: "status"
    className: "com.digitalpebble.stormcrawler.urlfrontier.StatusUpdaterBolt"
    parallelism: 4
  - id: "indexer"
    className: "com.digitalpebble.stormcrawler.indexing.DummyIndexer"
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
    to: "parse"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "parse"
    to: "indexer"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "fetcher"
    to: "warc"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "fetcher"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"
      
  - from: "indexer"
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

#  - from: "filespout"
#    to: "status"
#    grouping:
#      streamId: "status"
#      type: CUSTOM
#      customClass:
#        className: "com.digitalpebble.stormcrawler.util.URLStreamGrouping"
#       constructorArgs:
#         - "byDomain"
