package com.digitalpebble.stormcrawler;

import java.util.Map;

import org.apache.storm.metric.api.MultiCountMetric;
import org.apache.storm.task.OutputCollector;
import org.apache.storm.task.TopologyContext;
import org.apache.storm.topology.OutputFieldsDeclarer;
import org.apache.storm.topology.base.BaseRichBolt;
import org.apache.storm.tuple.Fields;
import org.apache.storm.tuple.Tuple;
import org.apache.storm.tuple.Values;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Captures the URLs sent by the spout and report the depth value as a metric
 **/
public class CustomMetricsReporterBolt extends BaseRichBolt {

	public static final Logger LOG = LoggerFactory.getLogger(CustomMetricsReporterBolt.class);

	protected OutputCollector collector;

	private MultiCountMetric eventCounter;

	public CustomMetricsReporterBolt() {
	}

	@Override
	public void execute(Tuple input) {
		// must have at least a URL and metadata, possibly a status
		String url = input.getStringByField("url");
		Metadata metadata = (Metadata) input.getValueByField("metadata");

		String d = metadata.getFirstValue("depth");
		if (d == null)
			d = "0";

		eventCounter.scope(d).incr();
		
		// seeing some beyond threshold - why?
		if (Integer.parseInt(d) > 5) {
			LOG.error("Above distance threshold of 5: {} \n {}", url, metadata.toString());
		}

		Values v = new Values(url, metadata);
		collector.emit(input, v);
		collector.ack(input);
	}

	@Override
	public void declareOutputFields(OutputFieldsDeclarer declarer) {
		Fields f = new Fields("url", "metadata");
		declarer.declare(f);
	}

	@Override
	public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
		this.collector = collector;
		this.eventCounter = context.registerMetric("depth.counter", new MultiCountMetric(), 60);
	}

}
