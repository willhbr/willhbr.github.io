---
title: "Simple Home Server Monitoring with Prometheus in Podman"
tags: homelab projects podman
---

The next step in my containerising journey is setting up [Prometheus][prometheus] monitoring. I'm not going to use this for alerts or anything fancy yet, just to collect data and see what the load and health of my server is and be able to track trends over time. In doing this I wanted:

[prometheus]: http://prometheus.io

- I don't want to edit a central YAML file when I start a new service
- Key container metrics (CPU/memory/etc) should be monitored automatically
- Prometheus itself should run in a container

There are plenty of existing posts on setting up Prometheus in a container, so I'll keep this short. I used [pod][pod] to configure the containers:

[pod]: https://pod.willhbr.net

```yaml
containers:
  prometheus:
    name: prometheus
    image: docker.io/prom/prometheus:latest
    network: prometheus
    volumes:
      prometheus_data: /prometheus
    bind_mounts:
      ./prometheus.yaml: /etc/prometheus/prometheus.yml
    ports:
      9090: 9090
    labels:
      prometheus.target: prometheus:9090

  podman-exporter:
    name: podman-exporter
    image: quay.io/navidys/prometheus-podman-exporter:latest
    bind_mounts:
      /run/user/1000/podman/podman.sock: /var/run/podman/podman.sock,ro
    environment:
      CONTAINER_HOST: unix:///var/run/podman/podman.sock
    run_flags:
      userns: keep-id
    network: prometheus
    labels:
      prometheus.target: podman-exporter:9882

  speedtest:
    name: prometheus_speedtest
    image: docker.io/jraviles/prometheus_speedtest:latest
    network: prometheus
    labels:
      prometheus.target: prometheus_speedtest:9516
      prometheus.labels:
        __scrape_interval__: 30m
        __scrape_timeout__: 2m
        __metrics_path__: /probe
```

`prometheus` contains the actual Prometheus application, which has its data stored in a volume. `podman-exporter` exports Podman container metrics, accessed by mounting in the Podman socket.[^socket] `speedtest` isn't essential, but I was curious to see whether I had any variations in my home internet speed, and running one more container wasn't difficult. This also forced me to work out how to customise the scraping of jobs configured via Prometheus HTTP service discovery.

[^socket]: This obviously gives the exporter full access to do anything to any container, so you've just kinda got to trust it's doing the right thing.

To meet my first requirement of having no global config, I needed to setup some kind of automatic service discovery system. Prometheus supports [fetching targets via an HTTP API](https://prometheus.io/docs/prometheus/latest/http_sd/)—all you have to do is return back a list of jobs to scrape in a basic JSON format. Since I already run a container that shows a status page for my containers (more on that another time, perhaps) I have an easy place to add this endpoint. You just need to add the endpoint into your `prometheus.yaml` config file once:

```yaml
scrape_configs:
  - job_name: endash
    http_sd_configs:
    - url: http://my_status_page:1234/http_sd_endpoint
```

That endpoint returns some JSON that looks like this:

```json
[
  {
    "targets": ["prometheus:9090"],
    "labels": {
      "host": "Steve",
      "job": "prometheus",
      "container_id": "4a98073041d6b"
    }
  },
  {
    "targets": ["prometheus_speedtest:9516"],
    "labels": {
      "host": "Steve",
      "job": "prometheus_speedtest",
      "container_id": "db95c10b425cc",
      "__scrape_interval__": "30m",
      "__scrape_timeout__": "2m",
      "__metrics_path__": "/probe"
    }
  }
]
```

`targets` is a list of instances to scrape for a particular job (each container is one job, so only one target in the list). `labels` defines additional labels added to those jobs. You can use this to override the job name (otherwise it'll unhelpfully be the name of the HTTP SD config, in my case `endash`) and set some of the scrape config values, if the target should be scraped on a different schedule.

My status dashboard has an endpoint that will look at all running containers and return an SD response based on the container labels. This allows me to define the monitoring config in the same place I define the container itself, rather than in some centralised Prometheus config. You can see in my `pods.yaml` file (above) that I use `prometheus.target` and `prometheus.labels` to make a container known to Prometheus as a job.

The thing that really makes this all work is Podman networks. The easiest way to get Prometheus running is to run it on the `host` network, so that it doesn't run in its own containerised network namespace. So when it scrapes some port on `localhost` that's the _host_ `localhost`, not the _container_ `localhost`. This works reasonably well if all your containers publish a port on the host. This is definitely an acceptable way of setting things up, but I wanted to be able to run containers without published ports and still monitor them.

You can do this by creating a Podman network and attaching any monitor-able containers to it, so that they are accessible via their container names:

```shell
> podman network create prometheus
> podman run -d --network prometheus --name network-test alpine:latest top
> podman run -it --network prometheus alpine:latest
$ ping network-test
PING network-test (10.89.0.16): 56 data bytes
64 bytes from 10.89.0.16: seq=0 ttl=42 time=0.135 ms
64 bytes from 10.89.0.16: seq=1 ttl=42 time=0.095 ms
...
```

I'm running `top` in the `network-test` container just to keep it running in the background for this example. If you ran a shell, it would exit immediately since there is no input connected.
{:class="caption"}

The one wrinkle of using a Podman network is that it makes accessing non-container jobs more difficult. I wanted to setup `node_exporter` to keep track of system-level metrics, and it can't run in a container as it needs full system access (or at least, it doesn't make sense to run in a container). Thankfully this ended up being super easy, I can just install `node_exporter` via `apt`:

```shell
$ sudo apt install prometheus-node-exporter
```

Which will automatically start a service running in the background and serving metrics on `localhost:9100/metrics`. To access this from our Prometheus container, you can just use the magic hostname `host.containers.internal`, which resolves to the current host. For example:

```shell
> podman run -it alpine:latest
$ ask add curl
$ curl host.containers.internal:9100/metrics
... a whole bunch of metrics
```

So I have to add _one_ static config into my `prometheus.yaml` file:

```yaml
scrape_configs:
  - job_name: steve
    static_configs:
      - targets: ['host.containers.internal:9100']
```

So now I've got a fully containerised, automatic monitoring system for anything running on my home server. Any new containers will get picked up by `podman-exporter`, and get their resource usage recorded automatically. If I integrate a Prometheus client library and export metrics, then I can just add monitoring config to the `pods.yaml` file for that project, and have my service discovery system pick it up and have it scraped automatically.

> I've added **a lot** of functionality to [pod][pod] since I [first wrote about it](/2023/06/08/pod-the-container-manager/), I'm aiming to get it cleaned up and documented better soon.
