# Totem de Pedidos - Kubernetes Deployment

Este diretório contém todos os manifestos Kubernetes necessários para fazer o deploy da aplicação **Totem de Pedidos** em um cluster Kubernetes.

## 📋 Arquivos Incluídos

| Arquivo | Descrição |
|---------|-----------|
| `namespace.yaml` | Namespace dedicado `totem-pedidos` |
| `configmap.yaml` | Configurações não-sensíveis da aplicação |
| `secret.yaml` | Credenciais e dados sensíveis (base64 encoded) |
| `migration-configmap.yaml` | Scripts SQL de migração do banco |
| `postgres-pvc.yaml` | PersistentVolumeClaim para PostgreSQL |
| `postgres-deployment.yaml` | Deployment do PostgreSQL |
| `postgres-service.yaml` | Service interno para PostgreSQL |
| `migration-job.yaml` | Job para executar migrações do banco |
| `app-deployment.yaml` | Deployment principal da aplicação Go |
| `app-service.yaml` | Service para a aplicação |
| `ingress.yaml` | Ingress para acesso externo |
| `hpa.yaml` | Horizontal Pod Autoscaler |
| `deploy.sh` | Script automatizado de deployment |

## 🚀 Deployment Rápido

### Pré-requisitos

1. **Cluster Kubernetes** funcionando
2. **kubectl** configurado e conectado ao cluster
3. **Ingress Controller** (NGINX recomendado)
4. **Metrics Server** (para HPA funcionar)

### Deployment Automático

```bash
# Navegar para o diretório
cd deploy/k8s/

# Executar o script de deployment
./deploy.sh
```

### Deployment Manual

Se preferir fazer o deployment manual, execute os comandos na seguinte ordem:

```bash
# 1. Criar namespace
kubectl apply -f namespace.yaml

# 2. Criar ConfigMaps
kubectl apply -f configmap.yaml
kubectl apply -f migration-configmap.yaml

# 3. Criar Secrets
kubectl apply -f secret.yaml

# 4. Criar recursos do PostgreSQL
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# 5. Aguardar PostgreSQL ficar pronto
kubectl wait --for=condition=Ready pod -l app=postgres -n totem-pedidos --timeout=300s

# 6. Executar migrações
kubectl apply -f migration-job.yaml
kubectl wait --for=condition=Complete job/migration-job -n totem-pedidos --timeout=300s

# 7. Fazer deploy da aplicação
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# 8. Aguardar aplicação ficar pronta
kubectl wait --for=condition=Available deployment/totem-pedidos-app -n totem-pedidos --timeout=300s

# 9. Criar Ingress e HPA
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

## 🛠️ Configurações Importantes

### 1. Imagem Docker

**IMPORTANTE**: Antes do deployment, certifique-se de:

1. Fazer o build da imagem Docker:
```bash
docker build -t totem-pedidos:latest .
```

2. Se usando registry externo, fazer push:
```bash
docker tag totem-pedidos:latest your-registry/totem-pedidos:latest
docker push your-registry/totem-pedidos:latest
```

3. Atualizar o `app-deployment.yaml` com a imagem correta:
```yaml
containers:
- name: totem-pedidos
  image: your-registry/totem-pedidos:latest  # Atualizar aqui
```

### 2. Configuração de DNS

Para acessar a aplicação via `totem-pedidos.local`, configure:

**Opção 1 - /etc/hosts:**
```bash
# Adicionar ao /etc/hosts
<CLUSTER_IP> totem-pedidos.local
```

**Opção 2 - DNS personalizado:**
Atualizar o `ingress.yaml` com seu domínio real:
```yaml
rules:
- host: seu-dominio.com  # Substituir aqui
```

### 3. Secrets e Credenciais

⚠️ **IMPORTANTE**: Os secrets no arquivo `secret.yaml` estão com valores de exemplo. Para produção:

1. **Atualize as credenciais do banco de dados**
2. **Configure os tokens reais do MercadoPago**
3. **Defina a URL correta para webhooks**

```bash
# Atualizar secrets (valores em base64)
echo -n "nova-senha" | base64
echo -n "novo-token" | base64
```

## 📊 Monitoramento e Verificação

### Comandos Úteis

```bash
# Ver todos os recursos
kubectl get all -n totem-pedidos

# Verificar pods
kubectl get pods -n totem-pedidos

# Ver logs da aplicação
kubectl logs -f deployment/totem-pedidos-app -n totem-pedidos

# Verificar HPA
kubectl get hpa -n totem-pedidos

# Verificar ingress
kubectl get ingress -n totem-pedidos

# Descrever deployment
kubectl describe deployment totem-pedidos-app -n totem-pedidos
```

### Health Checks

A aplicação possui endpoint de health check em `/health`:

```bash
# Via port-forward
kubectl port-forward svc/totem-pedidos-service 8080:80 -n totem-pedidos
curl http://localhost:8080/health

# Via ingress (se configurado)
curl http://totem-pedidos.local/health
```

## 🔧 Configurações Avançadas

### Scaling Manual

```bash
# Escalar manualmente
kubectl scale deployment totem-pedidos-app --replicas=5 -n totem-pedidos

# Ver status do HPA
kubectl get hpa totem-pedidos-hpa -n totem-pedidos
```

### Recursos e Limites

Os recursos estão configurados em `app-deployment.yaml`:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Autoscaling

O HPA está configurado para:
- **Mínimo**: 2 replicas
- **Máximo**: 10 replicas
- **CPU Target**: 70%
- **Memory Target**: 80%

## 📍 Endpoints da API

Após o deployment, a API estará disponível nos seguintes endpoints:

- `GET /health` - Health check
- `GET /docs` - Documentação Swagger
- `GET /products` - Produtos
- `GET /customers` - Clientes
- `GET /categories` - Categorias
- `GET /orders` - Pedidos
- `POST /payments/webhook` - Webhook MercadoPago

## 🗑️ Limpeza

Para remover completamente o deployment:

```bash
# Remover todos os recursos do namespace
kubectl delete namespace totem-pedidos

# Ou remover recursos individualmente
kubectl delete -f . -n totem-pedidos
```

## 🔒 Considerações de Segurança

1. **Secrets**: Nunca commitar secrets reais no repositório
2. **Network Policies**: Considere implementar políticas de rede restritivas
3. **RBAC**: Configure roles apropriados para o service account
4. **TLS**: Habilite HTTPS no ingress para produção
5. **Image Security**: Use imagens verificadas e escaneadas

## 📝 Troubleshooting

### Problemas Comuns

1. **Pod não inicia**: Verificar logs e events
```bash
kubectl describe pod <pod-name> -n totem-pedidos
kubectl logs <pod-name> -n totem-pedidos
```

2. **Banco não conecta**: Verificar service e credenciais
```bash
kubectl get svc postgres-service -n totem-pedidos
kubectl logs deployment/postgres-deployment -n totem-pedidos
```

3. **Ingress não funciona**: Verificar ingress controller
```bash
kubectl get ingress -n totem-pedidos
kubectl describe ingress totem-pedidos-ingress -n totem-pedidos
```

4. **HPA não escala**: Verificar metrics server
```bash
kubectl top pods -n totem-pedidos
kubectl describe hpa totem-pedidos-hpa -n totem-pedidos
