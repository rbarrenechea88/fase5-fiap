# FinOps - Otimização Financeira | SolidaryTech

## Estratégia de Tagging

Todos os recursos provisionados via Terraform possuem tags obrigatórias:

| Tag         | Valor           | Propósito                              |
|-------------|-----------------|----------------------------------------|
| Project     | SolidaryTech    | Identificação do projeto               |
| Environment | Production      | Segregação de ambientes                |
| CostCenter  | NGO-Core        | Centro de custo para alocação          |
| ManagedBy   | Terraform       | Rastreabilidade de provisionamento     |
| Service     | (nome-serviço)  | Alocação de custo por microsserviço    |

### Implementação no Terraform
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

---

## Rightsizing (Kubernetes)

Análise de consumo e ajuste de requests/limits:

| Serviço             | CPU Request | CPU Limit | Mem Request | Mem Limit | Justificativa                    |
|---------------------|-------------|-----------|-------------|-----------|----------------------------------|
| donation-service    | 100m        | 250m      | 128Mi       | 256Mi     | Hot path - Go leve, burst alto   |
| ngo-service         | 80m         | 200m      | 128Mi       | 256Mi     | CRUD simples, tráfego moderado   |
| volunteer-service   | 80m         | 200m      | 128Mi       | 256Mi     | DynamoDB = I/O bound, CPU baixa  |

**HPA configurado**: Scale baseado em CPU (70%) e memória (80%) para donation-service.

---

## Relatório de Forecast

### Estimativa Mensal (us-east-1)

| Recurso                        | Custo Estimado/Mês |
|--------------------------------|--------------------|
| EKS Cluster                    | $73.00             |
| EC2 (3x t3.medium)            | $99.36             |
| RDS PostgreSQL (2x db.t3.micro)| $29.20            |
| DynamoDB (on-demand)           | $5.00              |
| SQS                            | $1.00              |
| NAT Gateway                    | $32.40             |
| S3 (Velero backups)            | $2.30              |
| Data Transfer                  | $10.00             |
| **Total Estimado**             | **~$252/mês**      |

### Recomendações de Otimização

1. **Savings Plans**: Comprometer instâncias EKS nodes com 1-year Compute Savings Plan = ~30% de economia ($30/mês)
2. **Single NAT Gateway**: Já implementado (vs 3 NATs = economia de $64.80/mês)
3. **DynamoDB On-Demand**: Adequado para tráfego imprevisível de ONG (paga por request)
4. **S3 Lifecycle Policies**: Transição para Standard-IA após 7 dias, expiração em 30 dias
5. **Spot Instances**: Considerar para worker nodes não-críticos (volunteer-service) = ~60% economia
