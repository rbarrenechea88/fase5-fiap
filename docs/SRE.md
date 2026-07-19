# SRE - Engenharia de Confiabilidade | SolidaryTech

## Definição de SLIs, SLOs e SLA

### Serviço: donation-service (Caminho Crítico / Hot Path)

#### SLI 1: Taxa de Sucesso (Disponibilidade)
- **Definição**: Proporção de requisições HTTP ao donation-service que retornam status 2xx em relação ao total.
- **Fórmula**: `sum(rate(http_requests_total{service="donation-service", code=~"2.."}[5m])) / sum(rate(http_requests_total{service="donation-service"}[5m]))`
- **SLO**: 99.9% de taxa de sucesso em janela de 30 dias
- **Error Budget**: 0.1% = ~43 minutos de indisponibilidade por mês

#### SLI 2: Latência P99
- **Definição**: Tempo de resposta no percentil 99 das requisições ao donation-service.
- **Fórmula**: `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{service="donation-service"}[5m])) by (le))`
- **SLO**: Latência P99 < 500ms
- **Error Budget**: Máximo de 1% das requisições acima de 500ms

#### SLA com ONGs parceiras
- **Disponibilidade**: 99.9% uptime mensal
- **Latência**: Tempo de resposta médio < 200ms, P99 < 500ms
- **Compensação**: Em caso de violação, créditos operacionais serão concedidos às ONGs afetadas

---

## Dashboard SRE

O dashboard Grafana (`monitoring/grafana/dashboard-sre.json`) apresenta:
1. **Gauge de SLO**: Taxa de sucesso em tempo real vs target 99.9%
2. **Gauge de Latência P99**: Latência atual vs target 500ms
3. **Error Budget Burn**: Consumo do error budget ao longo do tempo
4. **Golden Metrics**: Traffic, Errors, Latency, Saturation (4 painéis)

---

## Estratégia de Redução do MTTR

### Detecção (< 1 min)
- Alertas Prometheus com thresholds agressivos
- AIOps (Datadog Watchdog / New Relic Applied Intelligence) para detecção de anomalias
- Distributed Tracing com OpenTelemetry para root cause analysis instantâneo

### Diagnóstico (< 5 min)
- Dashboards pré-construídos com golden metrics
- Correlação automática traces → logs → métricas
- Runbooks documentados para incidentes comuns

### Mitigação (< 10 min)
- HPA e auto-scaling para absorver picos
- Circuit breakers e retry patterns
- Rollback automático via ArgoCD (self-heal)

### Recuperação (< 15 min)
- Velero para restore de estado
- DR cross-region com Terraform modular
- Post-mortem obrigatório para prevenção

**MTTR Target**: < 15 minutos para incidentes de severidade P1
