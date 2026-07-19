# Plano de Continuidade de Negócios (PCN) | SolidaryTech

## 1. Objetivo

Garantir a continuidade operacional da plataforma SolidaryTech em caso de falhas regionais na AWS, assegurando que as doações nunca parem.

---

## 2. Classificação de Criticidade dos Serviços

| Serviço             | Criticidade | Justificativa                                     |
|---------------------|-------------|---------------------------------------------------|
| donation-service    | Crítico     | Caminho de receita - doações não podem parar      |
| ngo-service         | Alto        | Cadastro de ONGs - impacto em novas parcerias     |
| volunteer-service   | Médio       | Match de voluntários - tolerância a atrasos       |

---

## 3. RTO e RPO

### donation-service (Crítico)
- **RPO (Recovery Point Objective)**: 5 minutos
  - Justificativa: Dados financeiros de doações exigem perda mínima
  - Estratégia: RDS Multi-AZ com replicação síncrona
- **RTO (Recovery Time Objective)**: 15 minutos
  - Justificativa: Doações devem voltar em até 15 min
  - Estratégia: Terraform para levantar ambiente espelho em us-east-2

### ngo-service (Alto)
- **RPO**: 1 hora
  - Estratégia: Backup RDS automático com retenção de 7 dias
- **RTO**: 30 minutos
  - Estratégia: Terraform apply na região DR

### volunteer-service (Médio)
- **RPO**: 4 horas
  - Estratégia: DynamoDB Point-in-Time Recovery (PITR)
- **RTO**: 1 hora
  - Estratégia: Re-deploy via Terraform + ArgoCD na região DR

---

## 4. Estratégia de Disaster Recovery

### Implementação: Terraform Ativo-Passivo (Warm Standby)

**Região Primária**: us-east-1 (N. Virginia)
**Região DR**: us-east-2 (Ohio)

**Arquitetura:**
- Infraestrutura completa definida em `terraform/dr.tf`
- VPC, EKS e networking pré-provisionados em Ohio via Terraform
- O ambiente DR roda com capacidade reduzida (2 nodes vs 3) para economia
- Em caso de failover, escala para capacidade total

**Fluxo de Recovery:**
```
1. Incidente detectado (alerta/AIOps) → Runbook acionado
2. Confirmar indisponibilidade da região primária (< 2 min)
3. Escalar nodes DR: terraform apply -var="dr_desired_size=3"
4. ArgoCD sincroniza manifestos no cluster DR
5. Atualizar DNS (Route53 failover policy) para apontar ao cluster DR
6. Validar serviços + smoke tests
7. Comunicar stakeholders
```

**Comando para ativar DR completo:**
```bash
terraform apply -var="aws_region=us-east-2" -var="environment=DR"
```

---

## 5. Testes de DR

| Teste              | Frequência  | Responsável  |
|--------------------|-------------|--------------|
| Failover RDS       | Mensal      | SRE Lead     |
| DR Terraform Plan  | Quinzenal   | DevOps       |
| Full DR Drill      | Trimestral  | Toda equipe  |

---

## 6. Comunicação em Crise

| Nível     | Quem é notificado          | Canal          | Tempo    |
|-----------|----------------------------|----------------|----------|
| P1        | Toda equipe + Diretoria    | Slack + Email  | Imediato |
| P2        | Equipe técnica             | Slack          | < 5 min  |
| P3        | On-call                    | PagerDuty      | < 15 min |
