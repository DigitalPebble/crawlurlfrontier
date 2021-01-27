``` sh
mvn clean package
```

with a URLFrontier service running, inject the seeds

``` sh
java -cp target/crawlurlfrontier-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutUrls seeds.txt
```

then launch the crawl

``` sh
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux --local crawler.flux --sleep 86400000
```

