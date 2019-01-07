### 一个用于在本地部署Prometheus以及相关服务，并使用Prometheus监控他们的workshop。
基于MacOS  
尽量使用容器化的方式实现，demo内容包括
- 获取Prom自身状态 (done)
- 获取container状态 (done)
- 获取node状态 (done)
- 基于文件的Service Discovery (done)
- 对于kong，使用plugin,从而获取kong的状态 (done)
- 部署blackbox exporter, 通过（HTTP, HTTPS, DNS, TCP and ICMP）获取节点的状态信息。(done)
- 对于Spring boot 2.0+的应用，通过microExporter获取java程序状态
- 获取NodeJs应用状态
- 配置AlertManager报警
- Alert集成WeChat


### [Prometheus](https://prometheus.io/docs/introduction/overview/)获取自身状态  
prometheus.yml文件：
```
global:
  scrape_interval:     15s 
  evaluation_interval: 15s

rule_files:
  # - "first.rules"
  # - "second.rules"

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
```

本地使用容器的方式执行Prometheus:  
```docker run -p 9090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus```  

metrics:  
```
promhttp_metric_handler_requests_total
promhttp_metric_handler_requests_total{code="200"}
count(promhttp_metric_handler_requests_total)
rate(promhttp_metric_handler_requests_total{code="200"}[1m])
```

### 使用[CAdvisor](https://github.com/google/cadvisor)获取容器的数据：   
之后使用Prometheus获取CAdvisor数据：
```
scrape_configs:
- job_name: cadvisor
  scrape_interval: 5s
  static_configs:
  - targets:
    - cadvisor:8080
```
查看容器的metrics:
```
container_memory_usage_bytes{name="redis"}
```

### 使用[NodeExporter](https://github.com/prometheus/node_exporter)获取节点的硬件和系统内核相关Metrics：  
安装与使用Node-Exporter:
```
wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
tar xvfz node_exporter-0.17.0.linux-amd64.tar.gz
cd node_exporter-0.17.0.linux-amd64
./node_exporter
```
Metrics例如：
```node_filesystem_free_bytes{device="/dev/vda1"}```

### 使用 [FILE-BASED SERVICE DISCOVERY](https://github.com/prometheus/prometheus/tree/master/discovery) 发现目标  
Prometheus的配置文件：
```
scrape_configs:
- job_name: 'node'
  file_sd_configs:
  - files:
    - 'targets.json'
```
target.json文件的写法
```
[
  {
    "targets": [
      "localhost:9100"
    ],
    "labels": {
      "job": "node"
    }
  },
  {
    "targets": [
      "localhost:9200"
    ],
    "labels": {
      "job": "node"
    }
  }
]
```
使用`up{job="node"}`可以查看这个job里面起起来的target。   
通常情况下，建议使用JSON-generating process/tool 来做这件事。
