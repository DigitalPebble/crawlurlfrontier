name: "crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

config:
  warc: {"fs.s3a.access.key": "${ENV-[AWS_ACCESS_KEY_ID]}", "fs.s3a.secret.key": "${ENV-[AWS_SECRET_ACCESS_KEY]}"}

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
      - 50.0
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

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.urlfrontier.Spout"
    parallelism: 1

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
    parallelism: 1
  - id: "fetcher"
    className: "com.digitalpebble.stormcrawler.bolt.FetcherBolt"
    parallelism: 1
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 4
  - id: "warc"
    className: "com.digitalpebble.stormcrawler.warc.WARCHdfsBolt"
    parallelism: 1
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
          - "warc"
      - name: "withFsUrl"
        args:
          - "s3a://commoncrawl-temp-eu-west-3/"
  - id: "status"
    className: "com.digitalpebble.stormcrawler.urlfrontier.StatusUpdaterBolt"
    parallelism: 1
  - id: "indexer"
    className: "com.digitalpebble.stormcrawler.indexing.DummyIndexer"
    parallelism: 1

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
