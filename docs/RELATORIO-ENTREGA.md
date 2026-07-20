# Relatório de Entrega - Hackathon Fase 5 | SolidaryTech

## Integrantes

| Nome | RM | GitHub Username |
|------|----|-----------------| 
| [NOME] | [RM] | rbarrenechea88 |

## Links

- **Repositório:** https://github.com/rbarrenechea88/fase5-fiap
- **Vídeo:** [INSERIR LINK]

---

## Seção SRE: Definição Formal de SLI, SLO e SLA

### Serviço: donation-service (Hot Path / Caminho Crítico)

O donation-service é o componente mais crítico da plataforma SolidaryTech, pois processa doações financeiras. A engenharia de confiabilidade é aplicada com foco nas Golden Metrics.

### SLI (Service Level Indicators)

#### SLI 1 — Taxa de Sucesso (Disponibilidade)

| Atributo | Valor |
|----------|-------|
| **Definição** | Proporção de requisições HTTP que retornam status 2xx em relação ao total de requisições |
| **Fonte de dados** | Prometheus (métricas expostas pelo serviço) |
| **Fórmula** | `sum(rate(http_requests_total{service="donation-service", code=~"2.."}[5m])) / sum(rate(http_requests_total{service="donation-service"}[5m]))` |
| **Janela** | Rolling 5 minutos para detecção rápida, 30 dias para cálculo de SLO |

#### SLI 2 — Latência P99

| Atributo | Valor |
|----------|-------|
| **Definição** | Tempo de resposta no percentil 99 das requisições ao endpoint /donations |
| **Fonte de dados** | Prometheus histogram |
| **Fórmula** | `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{service="donation-service"}[5m])) by (le))` |
| **Janela** | Rolling 5 minutos |

### SLO (Service Level Objectives)

| SLI | SLO Target | Error Budget (30 dias) | Consequência de Violação |
|-----|-----------|----------------------|--------------------------|
| Taxa de Sucesso | 99.9% | 0.1% (~43 min/mês de indisponibilidade) | Freeze de deploys + investigação |
| Latência P99 | < 500ms | Máx 1% de requisições acima do threshold | Escalonamento para equipe de performance |

#### Error Budget Policy

- **> 75% restante:** Operação normal, deploys liberados
- **25-75% restante:** Alertas de atenção, reviews de PR obrigatórios
- **< 25% restante:** Freeze de deploys não-críticos, investigação ativa
- **0% (Budget esgotado):** Apenas hotfixes permitidos, post-mortem obrigatório

### SLA (Service Level Agreement) com ONGs Parceiras

| Métrica | Compromisso | Penalidade |
|---------|-------------|------------|
| Disponibilidade mensal | 99.9% uptime | Créditos operacionais proporcionais |
| Latência média | < 200ms | Relatório de ação corretiva |
| Latência P99 | < 500ms | Escalação para diretoria técnica |
| Tempo de resposta a incidentes P1 | < 15 minutos | Revisão do processo de on-call |

### Dashboard SRE (Grafana)

O dashboard "SolidaryTech - SRE Dashboard (Golden Metrics & SLOs)" no Grafana apresenta:

1. **Gauge de SLO** — Taxa de sucesso em tempo real vs target 99.9%
2. **Gauge de Latência P99** — Latência atual vs target 500ms
3. **Error Budget Burn** — Consumo do error budget ao longo do tempo
4. **Golden Metrics:**
   - Traffic (Request Rate por serviço)
   - Errors (Error Rate 5xx)
   - Latency (P50/P95/P99)
   - Saturation (CPU por pod)

### Alertas Configurados

| Alerta | Condição | Severidade |
|--------|----------|------------|
| DonationServiceErrorBudgetBurn | Error Budget < 25% por 5min | Critical |
| DonationServiceHighLatency | P99 > 500ms por 5min | Warning |

### MTTR (Mean Time To Recovery)

A stack de observabilidade contribui para redução do MTTR em 4 fases:

| Fase | Alvo | Mecanismo |
|------|------|-----------|
| Detecção | < 1 min | Alertas Prometheus + AIOps |
| Diagnóstico | < 5 min | Distributed Tracing + Dashboards |
| Mitigação | < 10 min | HPA auto-scale + ArgoCD rollback |
| Recuperação | < 15 min | DR Terraform + restore |

---

## Seção FinOps: Análise de Custos e Tagueamento

### Estratégia de Tagging

Todos os recursos AWS são provisionados via Terraform com tags obrigatórias aplicadas em `provider.default_tags`:

```hcl
provider "aws" {
  default_tags {
    tags = {
      Project     = "SolidaryTech"
      Environment = "Production"
      CostCenter  = "NGO-Core"
      ManagedBy   = "Terraform"
    }
  }
}
```

| Tag | Valor | Propósito |
|-----|-------|-----------|
| Project | SolidaryTech | Identificação do projeto para Cost Explorer |
| Environment | Production | Segregação de ambientes (Production/DR) |
| CostCenter | NGO-Core | Centro de custo para alocação financeira |
| ManagedBy | Terraform | Rastreabilidade de provisionamento |
| Service | ngo-service / donation-service / volunteer-service | Alocação por microsserviço |

### Evidência de Tags Aplicadas

Todos os recursos no console AWS (EKS, RDS, DynamoDB, SQS, VPC, Subnets, Security Groups) apresentam as tags obrigatórias. Evidência visual coletada no vídeo de demonstração.

### Rightsizing (Kubernetes)

Análise de consumo real vs alocado para otimização de requests/limits:

| Serviço | CPU Request | CPU Limit | Mem Request | Mem Limit | Justificativa |
|---------|-------------|-----------|-------------|-----------|---------------|
| donation-service | 100m | 250m | 128Mi | 256Mi | Hot path Go - leve mas precisa de burst |
| ngo-service | 80m | 200m | 128Mi | 256Mi | CRUD simples, tráfego moderado |
| volunteer-service | 80m | 200m | 128Mi | 256Mi | I/O bound (DynamoDB), CPU baixa |

HPA configurado para donation-service: scale 3→10 replicas baseado em CPU 70% e Memória 80%.

### Relatório de Forecast — Projeção Mensal (us-east-1)

| Recurso | Custo Estimado/Mês |
|---------|-------------------|
| EKS Cluster (control plane) | $73.00 |
| EC2 Nodes (3x t3.medium on-demand) | $99.36 |
| RDS PostgreSQL (2x db.t3.micro) | $29.20 |
| DynamoDB (on-demand, baixo volume) | $5.00 |
| SQS (baixo volume) | $1.00 |
| NAT Gateway (1x, single AZ) | $32.40 |
| ELB (2x Classic - Grafana + ArgoCD) | $36.00 |
| ECR (armazenamento de imagens) | $1.00 |
| CloudWatch Logs | $5.00 |
| Data Transfer | $10.00 |
| **Total Estimado** | **~$292/mês** |

### Recomendações de Otimização

| # | Recomendação | Economia Estimada |
|---|--------------|-------------------|
| 1 | Savings Plans 1 ano (EC2) | ~30% em compute = -$30/mês |
| 2 | Single NAT Gateway (já implementado) | Evita $64.80/mês vs 3 NATs |
| 3 | DynamoDB On-Demand (já implementado) | Adequado para tráfego imprevisível |
| 4 | S3 Lifecycle para logs antigos | -$2/mês |
| 5 | Spot Instances para worker nodes não-críticos | ~60% economia em EC2 |

---

## Seção Segurança e DR: Plano de Continuidade de Negócios

### RTO e RPO por Serviço

| Serviço | Criticidade | RPO | RTO | Estratégia |
|---------|-------------|-----|-----|------------|
| donation-service | Crítico | 5 min | 15 min | RDS Multi-AZ + Terraform DR |
| ngo-service | Alto | 1 hora | 30 min | RDS backup 7 dias + re-deploy |
| volunteer-service | Médio | 4 horas | 1 hora | DynamoDB PITR + re-deploy |

### Estratégia de Disaster Recovery: Terraform Ativo-Passivo

| Atributo | Valor |
|----------|-------|
| **Região Primária** | us-east-1 (N. Virginia) |
| **Região DR** | us-east-2 (Ohio) |
| **Tipo de DR** | Warm Standby via Terraform |
| **Código DR** | `terraform-dr/main.tf` |

#### Arquitetura DR

O código Terraform em `terraform-dr/` é idêntico à infraestrutura primária (VPC + EKS) mas configurado para us-east-2. Em caso de desastre regional:

```bash
# Comando para ativar DR em Ohio
cd terraform-dr/
terraform init
terraform apply -var="aws_access_key=XXX" -var="aws_secret_key=XXX"
```

#### Fluxo de Failover

```
1. Incidente regional detectado (alerta / AIOps)     [< 1 min]
2. Confirmar indisponibilidade da região primária     [< 2 min]
3. Executar terraform apply no módulo DR (Ohio)       [~10 min]
4. ArgoCD sincroniza manifestos no cluster DR         [< 2 min]
5. Atualizar DNS para apontar ao cluster DR           [< 1 min]
6. Validar serviços + smoke tests                     [< 2 min]
7. Comunicar stakeholders                             [imediato]
```

**RTO total estimado: ~15 minutos**

#### Proteção de Dados

| Camada | Mecanismo | RPO |
|--------|-----------|-----|
| RDS (donation-db) | Multi-AZ replicação síncrona | ~0 (failover automático) |
| RDS (ngo-db) | Backup automático retenção 7 dias | 1 hora |
| DynamoDB | Point-in-Time Recovery (PITR) | Qualquer ponto nos últimos 35 dias |

### Testes de DR

| Teste | Frequência | Responsável |
|-------|-----------|-------------|
| Failover RDS Multi-AZ | Mensal | SRE Lead |
| Terraform Plan DR (validação) | Quinzenal | DevOps |
| Full DR Drill (terraform apply + deploy) | Trimestral | Toda equipe |

---

## Seção ITSM/AIOps: Ciclo de Vida de Incidentes

### Configuração AIOps

| Atributo | Configuração |
|----------|--------------|
| **Ferramenta** | Prometheus + Grafana Alerting + integração APM |
| **Detecção de Anomalias** | Recording rules baseadas em desvios das Golden Metrics |
| **Sensibilidade** | Alta para donation-service (crítico), Média para demais |
| **Notificações** | Alertmanager → Slack + PagerDuty |

### Alertas Inteligentes

| Tipo de Anomalia | Ação Automática |
|------------------|-----------------|
| Spike de latência P99 > 500ms | Scale-up HPA + alerta Slack |
| Error rate > 0.1% (Error Budget burn) | Page on-call + investigação |
| Queda de throughput > 50% | Alerta + verificação de upstream |
| CPU > 80% sustained | Node auto-scale + notificação FinOps |

### Ciclo de Vida do Incidente

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CICLO DE VIDA DO INCIDENTE                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐      │
│  │ DETECÇÃO │───▶│ TRIAGEM  │───▶│MITIGAÇÃO │───▶│RESOLUÇÃO │      │
│  │  < 1min  │    │  < 3min  │    │ < 10min  │    │ < 30min  │      │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘      │
│       │                                                │             │
│       │                ┌──────────────┐                │             │
│       └───────────────▶│ POST-MORTEM  │◀───────────────┘             │
│                        │   < 48h      │                              │
│                        └──────────────┘                              │
│                               │                                      │
│                        ┌──────────────┐                              │
│                        │ COMUNICAÇÃO  │ (paralelo a todas as fases)  │
│                        └──────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
```

### Etapas Detalhadas

#### 1. Detecção (Target: < 1 minuto)

| Atributo | Descrição |
|----------|-----------|
| **Fonte** | Prometheus alerting rules + AIOps anomaly detection |
| **Mecanismo** | Threshold violado (SLO) ou anomalia detectada (desvio do baseline) |
| **Saída** | Alerta disparado → incidente criado automaticamente |

#### 2. Triagem (Target: < 3 minutos)

| Atributo | Descrição |
|----------|-----------|
| **Responsável** | Engenheiro on-call (rotação PagerDuty) |
| **Ações** | Classificar severidade (P1/P2/P3), identificar serviço afetado via traces, acionar equipe se P1 |
| **Ferramentas** | Grafana dashboards, distributed tracing |

#### 3. Mitigação (Target: < 10 minutos)

| Tipo | Ação |
|------|------|
| **Automática** | Rollback via ArgoCD (se deploy recente), Scale-up via HPA, Failover DR |
| **Manual** | Feature flags, redirect de tráfego, isolamento de componente |

#### 4. Resolução (Target: < 30 minutos)

| Atributo | Descrição |
|----------|-----------|
| **Ações** | Fix definitivo, deploy via pipeline CI/CD, validação com smoke tests |
| **Critério de saída** | SLOs restaurados + zero erros por 5 minutos |

#### 5. Post-Mortem (Target: < 48h)

| Seção | Conteúdo |
|-------|----------|
| Timeline | Cronologia minuto a minuto do incidente |
| Root Cause | Análise 5 Whys |
| Impacto | Consumo de Error Budget + usuários afetados |
| Action Items | Melhorias com owners e deadlines |
| Lições | Blameless — foco em melhorias sistêmicas |

#### 6. Comunicação

| Momento | Público | Conteúdo |
|---------|---------|----------|
| Detecção | Equipe técnica | "Investigando anomalia em X" |
| Triagem | Stakeholders internos | "Incidente P1 confirmado" |
| Mitigação | ONGs parceiras (se impacto) | "Serviço parcialmente restaurado" |
| Resolução | Todos | "Incidente resolvido" |
| Post-Mortem | Equipe + Diretoria | Documento completo |

### Métricas de ITSM

| Métrica | Target | Como é medido |
|---------|--------|---------------|
| MTTD (Mean Time To Detect) | < 1 min | Tempo entre início do problema e primeiro alerta |
| MTTA (Mean Time To Acknowledge) | < 3 min | Tempo entre alerta e acknowledge no PagerDuty |
| MTTR (Mean Time To Recovery) | < 15 min | Tempo entre detecção e SLOs restaurados |
| MTBF (Mean Time Between Failures) | > 30 dias | Média entre incidentes P1 |
