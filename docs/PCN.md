# Plano de Continuidade de Negócios (PCN) | SolidaryTech

## 1. Objetivo

Garantir a continuidade operacional da plataforma SolidaryTech em caso de falhas no provedor de nuvem, desastres naturais ou incidentes cibernéticos, assegurando que as doações nunca parem.

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
  - Estratégia: Failover automático RDS + ArgoCD self-heal

### ngo-service (Alto)
- **RPO**: 1 hora
  - Estratégia: Backup RDS com retenção de 7 dias
- **RTO**: 30 minutos
  - Estratégia: Restore do backup + re-deploy via ArgoCD

### volunteer-service (Médio)
- **RPO**: 4 horas
  - Estratégia: DynamoDB Point-in-Time Recovery (PITR)
- **RTO**: 1 hora
  - Estratégia: Restore DynamoDB + re-deploy

---

## 4. Estratégia de Disaster Recovery

### Implementação: Velero + Cross-Region Backup (Opção A)

**Componentes:**
1. **Velero** no cluster EKS: Backup diário dos manifestos e PVCs
2. **S3 Cross-Region Replication**: Bucket de backups replicado para us-west-2
3. **RDS Multi-AZ**: Failover automático para donation-db
4. **DynamoDB PITR**: Restore para qualquer ponto no tempo (últimas 35 dias)

**Fluxo de Recovery:**
```
1. Incidente detectado (alerta/AIOps) → Runbook acionado
2. Confirmar impacto (< 2 min)
3. Se região indisponível:
   a. Executar terraform apply -var="aws_region=us-west-2" (ambiente espelho)
   b. Velero restore do último backup no novo cluster
   c. Atualizar DNS (Route53 failover policy)
4. Validar serviços + smoke tests
5. Comunicar stakeholders
```

### Terraform Modular para DR (Opção B - Warm Standby)

O Terraform é modularizado para permitir levantar ambiente espelho em outra região com um único comando:

```bash
terraform apply -var="aws_region=us-west-2" -var="environment=DR"
```

---

## 5. Testes de DR

| Teste              | Frequência  | Responsável  | Último Teste |
|--------------------|-------------|--------------|--------------|
| Failover RDS       | Mensal      | SRE Lead     | -            |
| Velero Restore     | Quinzenal   | DevOps       | -            |
| Full DR Drill      | Trimestral  | Toda equipe  | -            |

---

## 6. Comunicação em Crise

| Nível     | Quem é notificado          | Canal          | Tempo    |
|-----------|----------------------------|----------------|----------|
| P1        | Toda equipe + Diretoria    | Slack + Email  | Imediato |
| P2        | Equipe técnica             | Slack          | < 5 min  |
| P3        | On-call                    | PagerDuty      | < 15 min |
