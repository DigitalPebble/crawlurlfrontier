This has been generated by the StormCrawler Maven Archetype as a starting point for building your own crawler.
Have a look at the code and resources and modify them to your heart's content. 

With Storm installed, you must first generate an uberjar:

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

Note that in local mode, Flux uses a default TTL for the topology of 60 secs. The command above runs the topology for 24 hours.

It is best to run the topology with `--remote` to benefit from the Storm UI and logging. In that case, the topology runs continuously, as intended.  
