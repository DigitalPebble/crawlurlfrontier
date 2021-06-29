``` sh
mvn clean package
```

Inject the seeds

```
java -cp ./target/crawlurlfrontier-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutURLs -f seeds.txt 
```

before submitting the topology using the storm command:

``` sh
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux crawler.flux
```

If the cluster is on Docker

```
docker exec -it nimbus bash
cd crawler
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux crawler.flux
```


