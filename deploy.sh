function deploy_prometheus() {
    echo "Deploy Prometheus container locally on 9090"
    docker run -p 9090:9090 \
        -v ./prometheus.yml:/etc/prometheus/prometheus.yml \
        prom/prometheus
}

function deploy_alert_manager() {
    echo "Deploy AlertManager container locally on 9093"
    docker run -p 9093:9093 \
        -v ./alertmanager.yml:/etc/alertmanager/config.yml \
        prom/alertmanager \
        --config.file=/etc/alertmanager/config.yml
}

function deploy_grafana() {
    echo "Deploy Grafana container locally on 3001"
    docker run -d --name=grafana -p 3001:3000 grafana/grafana
}

function deploy_prometheus_and_cAdvisor() {
    echo "Deploy Prometheus container locally and cAdvisor and  Redis Server"
    docker-compose up
}

function install_node_exporter() {
    PORT=${1:"9100"}

    echo "Install node exporter"
    wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.darwin-amd64.tar.gz
    tar xvfz node_exporter-0.17.0.darwin-amd64.tar.gz
    cd node_exporter-0.17.0.darwin-amd64
    ./node_exporter --web.listen-address=":${PORT}"
}

case $1 in
    deploy_prometheus) deploy_prometheus;;
    deploy_alert_manager) deploy_alert_manager;;
    deploy_prometheus_and_cAdvisor) deploy_prometheus_and_cAdvisor;;
    deploy_grafana) deploy_grafana;;
    install_node_exporter) install_node_exporter;;
    *) echo "Error command";;
esac
