#!/usr/bin/env bash

function deploy_prometheus() {
    echo "Deploy Prometheus container locally on 9090"
    docker run -p 9090:9090 \
        -v `pwd`/prometheus.yml:/etc/prometheus/prometheus.yml \
        prom/prometheus
}

function deploy_alert_manager() {
    echo "Deploy AlertManager container locally on 9093"
    docker run -p 9093:9093 \
        -v `pwd`/alertmanager.yml:/etc/alertmanager/config.yml \
        prom/alertmanager \
        --config.file=/etc/alertmanager/config.yml
}

function deploy_grafana_and_integrate_with_oauth() {
    echo "Deploy Grafana container locally on 3001"
    docker run -d --name=grafana -p 3001:3001 \
    -v `pwd`/grafana/custom.ini:/etc/grafana/grafana.ini \
    grafana/grafana
}

function deploy_prometheus_and_cAdvisor() {
    echo "Deploy Prometheus container(9090) locally and cAdvisor(8080) and  Redis Server(6379)"
    docker-compose up
}

function install_node_exporter() {
    PORT=${1:-9100}

    echo "Install node exporter on ${PORT}"
    wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.darwin-amd64.tar.gz
    tar xvfz node_exporter-0.17.0.darwin-amd64.tar.gz
    cd node_exporter-0.17.0.darwin-amd64
    ./node_exporter --web.listen-address=":${PORT}"
}

function deploy_kong() {
    echo "create docker network"
    docker network create kong-net

    echo "Deploy postgresSql container for kong on 5432"
    docker run -d --name kong-database \
               --network=kong-net \
               -p 5432:5432 \
               -e "POSTGRES_USER=kong" \
               -e "POSTGRES_DB=kong" \
               postgres:9.6
    echo "Sleep a while to wait the db ready"
    sleep 5

    echo "Prepare kong database"
    docker run --rm \
        --network=kong-net \
        --link kong-database:kong-database \
        -e "KONG_DATABASE=postgres" \
        -e "KONG_PG_HOST=kong-database" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        kong:latest kong migrations up

    echo "Start kong on 8000、8001、8443、8444"
    docker run -d --name kong \
    --network=kong-net \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_HOST=kong-database" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    kong:latest

    enable_kong_prometheus_plugin
}

function enable_kong_prometheus_plugin() {
    echo "Enable kong prometheus plugin"
    curl http://localhost:8001/plugins -d name=prometheus
}

function install_black_box_exporter_and_test_probe_baidu() {
    echo "Install black box exporter for prom on 9115"
    docker run -d \
        -p 9115:9115 \
        --name blackbox_exporter \
        -v `pwd`/blackbox_config:/config \
        prom/blackbox-exporter \
        --config.file=/config/blackbox.yml
    echo "Probe baidu"
    curl "http://localhost:9115/probe?module=http_2xx&target=baidu.com"
}

case $1 in
    deploy_prometheus) deploy_prometheus;;
    deploy_alert_manager) deploy_alert_manager;;
    deploy_prometheus_and_cAdvisor) deploy_prometheus_and_cAdvisor;;
    deploy_grafana) deploy_grafana_and_integrate_with_oauth;;
    deploy_kong) deploy_kong;;
    install_node_exporter) install_node_exporter $2;;
    install_black_box_exporter_and_test_probe_baidu) install_black_box_exporter_and_test_probe_baidu;;
    *) echo "Error command";;
esac
