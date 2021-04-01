``` sh
mvn clean package
```

Inject the seeds

```
java -cp ./target/crawlurlfrontier-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutURLs seeds.txt 
```

before submitting the topology using the storm command:

``` sh
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux --local crawler.flux --sleep 86400000
```

