# Helm chart for Peertube

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0/)
![AppVersion: v8.0.2](https://img.shields.io/badge/AppVersion-v8.0.2-informational?style=flat-square/)
![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square/)

## About
This chart bootstraps a [PeerTube](https://joinpeertube.org/) deployment on a Kubernetes cluster using the Helm package manager.

This allows you to deploy the main application and work with runners within one chart.

## Prerequisites

- Kubernetes cluster `>=v1.31.x`
- Helm `3.x`
- External-managed Redis and PostgreSQL
- For runner autoscaling, you may need to install [KEDA](https://keda.sh/) on your Kubernetes cluster (see [Runner Autoscaling](#runner-autoscaling))
- To automatically generate a certificate for Ingress using `server.certificate` you must have cert-manager installed in your Kubernetes cluster

## Quick Start

Before installation, you need to configure the following required parameters in your `values.yaml`:

- `server.config.*` - PeerTube server configuration (admin credentials, secrets, etc.)
- `server.externalPostgres`
- `server.externalRedis`

Optional configurations you may want to set:

- `server.ingress`
- `server.objectStorage` - S3-compatible object storage for files
- `runner` - Enable and configure remote runners for various jobs (requires `*.remote_runners.enabled: true` in `server.config.raw`. See [Configuration](#configuration))

**Add the PeerTube Helm repository:**

```console
$ helm repo add peertube https://zendet.github.io/peertube-helm/
```

**Create a namespace:**

```console
$ kubectl create namespace peertube
```

**Install the PeerTube chart:**

```console
$ helm install peertube peertube/peertube -n peertube -f values.yaml
```

## Configuration

### Server Configuration

The main PeerTube server configuration is set through `server.config.raw`, which accepts YAML that follows the [PeerTube configuration format](https://github.com/Chocobozzz/PeerTube/blob/develop/config/default.yaml).

**IMPORTANT**: 
- Do not include `database`, `redis`, `secrets`, or `object_storage` keys in `server.config.raw`, because these are configured separately via `server.externalPostgres`, `server.externalRedis`, `server.config.secrets`, and `server.objectStorage`.
- If you enable `remote_runners` in the configuration, you must also set `runner.enabled: true`.

### Runner Configuration

Runners are configured via `runner.runnerGroups`. Each group can handle specific job types and can be scaled independently using KEDA (see [Runner Autoscaling](#runner-autoscaling)).

**IMPORTANT**:
- You can use a runner image that includes a different transcription engine. For example, use the [0.4.0-openai](https://hub.docker.com/repository/docker/zendet/peertube-runner/tags/0.4.0-openai) image tag: set `runner.container.image.tag` to `0.4.0-openai`.

Example runner group:

```yaml
runner:
  enabled: true
  runnerGroups:
    - name: "VOD Transcoding Runners"
      id: "vod"
      replicas: 1
      jobTypes:
        - vod-web-video-transcoding
        - vod-hls-transcoding
        - vod-audio-merge-transcoding
      keda:
        enabled: true
        maxReplicas: 10
      config:
        raw: |
          jobs:
            concurrency: 2
          ffmpeg:
            threads: 0
            nice: 20
          transcription:
            engine: whisper-ctranslate2
            enginePath: /usr/local/bin/whisper-ctranslate2
            model: large-v2
```

See the [values.yaml](values.yaml) file for a complete list of available configuration options.

## Monitoring

### Prometheus Metrics

This Helm chart can expose PeerTube metrics to Prometheus. To enable metrics, set:

```yaml
server:
  metricsService:
    create: true
    port: 9091
```

Currently, the `enabled` flag in the PeerTube configuration is controlled by `server.metricsService.create` through Helm templating:

```yaml
server:
  config:
    raw: |
      open_telemetry:
        metrics:
          enabled: {{ .Values.server.metricsService.create }}
```

You can change this behavior as needed.

### ServiceMonitor

If you're using Prometheus Operator, you can enable automatic service discovery:

```yaml
server:
  serviceMonitor:
    enabled: true
    interval: 30s
    scrapeTimeout: 25s
```

### Grafana Dashboards

The chart includes a Grafana dashboard (which was taken from [here](https://docs.joinpeertube.org/maintain/observability#visualize-data-in-grafana)) for PeerTube server metrics. The dashboard has been rewritten and focuses on core PeerTube metrics.

What's included:
- PeerTube server metrics
- Performance and health indicators

What's excluded:
- Loki log panels
- Jaeger/Tempo trace panels

To enable the dashboard:

```yaml
server:
  grafana:
    dashboards:
      metrics:
        create: true
```

You can also use GrafanaDashboard CRD if Grafana Operator is installed:

```yaml
server:
  grafana:
    grafanaDashboard:
      enabled: true
```

The dashboard will be available as a ConfigMap that can be imported into Grafana, or automatically discovered if using Grafana Operator.

## Runner autoscaling

The chart supports automatic scaling of runner pods using [KEDA](https://keda.sh/) based on the number of pending jobs in the PostgreSQL database.

### How it works

PeerTube stores runner jobs in the PostgreSQL `runnerJob` table. KEDA scales runners by counting the number of jobs with state `PENDING` (1) or `WAITING_FOR_PARENT_JOB` (5) in this table.

### Configuration

**Global KEDA defaults** (applied to all runner groups unless overridden):

```yaml
runner:
  kedaDefaults:
    enabled: false
    minReplicas: 1
    maxReplicas: 20
    cooldownPeriod: 300
    pollingInterval: 30
    
    postgresql:
      host: ""
      port: "5432"
      userName: "peertube"
      dbName: "peertube"
      sslmode: "disable"
      targetQueryValue: "1"
      existingSecret: ""
      passwordKey: "postgres-password"
```

**Per-group KEDA settings** (override defaults for specific runner groups):

```yaml
runner:
  runnerGroups:
    - name: "VOD Transcoding Runners"
      id: "vod"
      jobTypes:
        - vod-web-video-transcoding
        - vod-hls-transcoding
        - vod-audio-merge-transcoding

      keda:
        enabled: false
        maxReplicas: 10
```

**Job Types**

You can find the job types available for filtering [here](https://github.com/Chocobozzz/PeerTube/blob/develop/packages/models/src/runners/runner-jobs/runner-job-type.type.ts).

**Verifying KEDA Scaling**

To manually check what KEDA counts for a specific runner group, run this SQL query in your PostgreSQL database:

```sql
SELECT COALESCE(COUNT(*),0)::integer 
FROM "runnerJob" 
WHERE state IN (1, 5)
  AND "type" IN ('job-type1', 'job-type2');
```

Replace the `'job-type1'` and `'job-type2'` with those configured in your `runnerGroups[].jobTypes`.

**Advanced Configuration**

You can override the default SQL query entirely:

```yaml
runner:
  kedaDefaults:
    postgresql:
      query: ""
```

When `query` is set, the `jobTypes` filter is ignored.

### Live streaming

To enable live streaming in the server configuration, check [PeerTube documentation](https://docs.joinpeertube.org/admin/configuration#live-streaming)

To expose ports for **RTMP** and **RTMPS**, you need to set `server.liveService.create` to `true`.

PeerTube listen ports (`live.rtmp.port`, `live.rtmps.port`) are configured in `server.config.raw`; the live Service and NodePort/LB/Ingress expose them.

To reach the live Service from the internet (e.g. for OBS), you need to expose it:
 - Use a LoadBalancer (`server.liveService.type: LoadBalancer`) if your cluster provides one
 - Use a NodePort (`server.liveService.type: NodePort` and optionally `server.liveService.nodePortRtmp` / `server.liveService.nodePortRtmps`)
 - Use an Ingress TCP passthrough so that port 1935 (and 1936 for RTMPS) is forwarded to the live Service

### Getting Help

You can get help at:

* Chat<a name="contact"></a>:
  * Matrix (bridged on IRC and [Discord](https://discord.gg/wj8DDUT)) : **[#peertube:matrix.org](https://matrix.to/#/#peertube:matrix.org)**
  * IRC : **[#peertube on irc.libera.chat:6697](https://web.libera.chat/#peertube)**
* Forum:
  * Framacolibri: [https://framacolibri.org/c/peertube](https://framacolibri.org/c/peertube)
