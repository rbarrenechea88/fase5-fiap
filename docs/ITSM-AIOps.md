# ITSM e AIOps - Gestão Preditiva | SolidaryTech

## 1. Configuração de AIOps

### Ferramenta: Datadog Watchdog / New Relic Applied Intelligence

**Funcionalidades Ativadas:**
- Detecção automática de anomalias em latência, error rate e throughput
- Correlação de eventos entre serviços (distributed tracing)
- Previsão de degradação antes do impacto ao usuário
- Root Cause Analysis automático baseado em ML

**Configuração:**
- Baseline de comportamento: aprendizado de 2 semanas de dados normais
- Sensibilidade: Alta para donation-service (crítico), Média para demais
- Notificações: Integração com PagerDuty e Slack

### Alertas Inteligentes
| Tipo de Anomalia              | Ação Automática                           |
|-------------------------------|-------------------------------------------|
| Spike de latência             | Scale-up HPA + alerta Slack               |
| Aumento de error rate         | Rollback ArgoCD + page on-call            |
| Queda de throughput           | Investigação automática + alerta          |
| Saturação de recursos         | Node scale-up + notificação FinOps        |

---

## 2. Ciclo de Vida de Incidentes (ITSM)

### Fluxo Completo

```
┌─────────────────────────────────────────────────────────────────┐
│                    CICLO DE VIDA DO INCIDENTE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ DETECÇÃO │───▶│TRIAGEM   │───▶│MITIGAÇÃO │───▶│RESOLUÇÃO │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │                                                  │       │
│       │               ┌──────────────┐                   │       │
│       └──────────────▶│ POST-MORTEM  │◀──────────────────┘       │
│                       └──────────────┘                           │
│                              │                                    │
│                       ┌──────────────┐                           │
│                       │ COMUNICAÇÃO  │                           │
│                       └──────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

### Etapas Detalhadas

#### 1. Detecção (Tempo alvo: < 1 minuto)
- **Fonte**: AIOps (Watchdog/Applied Intelligence) + Alertas Prometheus
- **Mecanismo**: Anomalia detectada automaticamente via ML ou threshold violado
- **Saída**: Incidente criado automaticamente no sistema de gestão

#### 2. Triagem (Tempo alvo: < 3 minutos)
- **Responsável**: On-call engineer (via PagerDuty rotation)
- **Ações**:
  - Classificar severidade (P1/P2/P3)
  - Identificar serviço afetado via distributed tracing
  - Acionar equipe se P1

#### 3. Mitigação (Tempo alvo: < 10 minutos)
- **Ações automáticas** (quando possível):
  - Rollback via ArgoCD (se deploy recente)
  - Scale-up via HPA
  - Failover para região DR (se impacto regional)
- **Ações manuais**:
  - Feature flags para desabilitar funcionalidade com bug
  - Redirect de tráfego

#### 4. Resolução (Tempo alvo: < 30 minutos)
- **Ações**:
  - Fix definitivo aplicado e testado
  - Deploy via pipeline CI/CD normal
  - Validação com smoke tests
  - Confirmar restauração dos SLOs

#### 5. Post-Mortem (Tempo alvo: < 48h após resolução)
- **Template**:
  - Timeline do incidente
  - Root cause (5 Whys)
  - Impacto em SLO/Error Budget
  - Action items com owners e deadlines
  - Lições aprendidas
- **Regra**: Blameless - foco em melhorias sistêmicas

#### 6. Comunicação
| Momento        | Público              | Conteúdo                          |
|----------------|----------------------|-----------------------------------|
| Detecção       | Equipe técnica       | "Investigando anomalia em X"      |
| Triagem        | Stakeholders         | "Incidente P1 confirmado em X"    |
| Mitigação      | ONGs afetadas        | "Serviço restaurado parcialmente" |
| Resolução      | Todos                | "Incidente resolvido"             |
| Post-Mortem    | Equipe + Diretoria   | Documento completo + action items |

---

## 3. Métricas de ITSM

| Métrica | Target          | Medição                          |
|---------|-----------------|----------------------------------|
| MTTD    | < 1 minuto      | AIOps detection time             |
| MTTA    | < 3 minutos     | Time to acknowledge (PagerDuty)  |
| MTTR    | < 15 minutos    | Time to recover (SLO restored)   |
| MTBF    | > 30 dias       | Mean time between failures       |
