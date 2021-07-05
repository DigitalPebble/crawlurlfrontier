# Crawl with URLFrontier

In the context of the Fed4Fire and NLNet fundings of URL Frontier.

First set the credentials for AWS

`export AWS_ACCESS_KEY_ID=...`
`export AWS_SECRET_ACCESS_KEY=...`

``` sh
mvn clean package
```

Inject the seeds

```
java -cp ./target/crawlurlfrontier-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutURLs -f top1M.hosts.commoncrawl
```

before submitting the topology using the storm command:

``` sh
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux crawler.flux --filter test.properties
```

If the cluster is on Docker

```
docker exec -it nimbus bash
cd crawler
storm jar target/crawlurlfrontier-1.0-SNAPSHOT.jar  org.apache.storm.flux.Flux crawler.flux
```


