# Deploy

Infraestrutura de deploy dos microsserviços via Docker Compose + Nginx.

## Arquitetura

```
Internet → :80 → Nginx (reverse proxy)
                    ├── /api        → security:3001
                    ├── /api-docs   → security:3001
                    ├── /api/negocios → bff-negocios:3002
                    └── /bff-docs   → bff-negocios:3002
```

## Arquivos

| Arquivo | Descrição |
|---|---|
| `docker-compose.yml` | Serviços: security, bff-negocios, nginx |
| `nginx.conf` | Reverse proxy com resolver dinâmico (não falha se um serviço estiver fora) |
| `.env.example` | Variáveis de ambiente (copie para `.env` e preencha) |
| `setup-vps.sh` | Script de setup inicial da VPS |

## Setup da VPS

### Requisitos do servidor
- Ubuntu 22.04+
- Acesso root via SSH
- Portas abertas no painel do provedor: **22** (SSH), **80** (HTTP), **443** (HTTPS)

### 1. Rodar o setup

```sh
ssh root@SEU_IP
curl -fsSL https://raw.githubusercontent.com/code-express-project/deploy/main/setup-vps.sh | bash
```

Isso instala Docker, cria `/opt/apps/` e configura o firewall.

### 2. Copiar arquivos para o servidor

```sh
scp docker-compose.yml nginx.conf .env root@SEU_IP:/opt/apps/
```

### 3. Configurar chave SSH para GitHub Actions

```sh
# Gerar chave (na máquina local)
ssh-keygen -t ed25519 -C "github-actions"

# Copiar para o servidor
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@SEU_IP
```

A chave **privada** (`~/.ssh/id_ed25519`) será usada como secret `SERVER_SSH_KEY` no GitHub.

### 4. Subir os containers

```sh
ssh root@SEU_IP
cd /opt/apps
docker compose up -d
```

## GitHub Secrets

Cada repositório precisa dos seus próprios secrets para o deploy automático.

### security

| Secret | Descrição |
|---|---|
| `DOCKER_USERNAME` | Usuário do Docker Hub |
| `DOCKER_PASSWORD` | Senha/token do Docker Hub |
| `SERVER_HOST` | IP da VPS |
| `SERVER_USER` | Usuário SSH (ex: `root`) |
| `SERVER_SSH_KEY` | Chave privada SSH |
| `DB_USER` | Usuário do PostgreSQL |
| `DB_HOST` | Host do PostgreSQL |
| `DB_NAME` | Nome do banco |
| `DB_PASSWORD` | Senha do banco |
| `DB_PORT` | Porta do banco |
| `JWT_SECRET` | Chave secreta JWT |
| `JWT_REFRESH_SECRET` | Chave secreta refresh token |
| `EMAIL_USER` | Email para envio |
| `EMAIL_PASS` | App Password do Gmail |
| `TOKEN_EXPIRATION` | Expiração do token (ex: `1h`) |
| `APP_NAME` | Nome da aplicação |

### bff-negocios

| Secret | Descrição |
|---|---|
| `DOCKER_USERNAME` | Usuário do Docker Hub |
| `DOCKER_PASSWORD` | Senha/token do Docker Hub |
| `SERVER_HOST` | IP da VPS |
| `SERVER_USER` | Usuário SSH (ex: `root`) |
| `SERVER_SSH_KEY` | Chave privada SSH |

## Deploy automático

Cada projeto tem seu próprio workflow em `.github/workflows/deploy.yml`. O fluxo é:

1. Push na `main`
2. GitHub Actions builda a imagem Docker
3. Publica no Docker Hub (`luidigas/<projeto>:latest`)
4. SSH na VPS
5. `docker compose pull <projeto>` + `docker compose up -d --no-deps --force-recreate <projeto>`

Os projetos são **independentes** — o deploy de um não afeta o outro.

## Comandos úteis na VPS

```sh
cd /opt/apps

# Ver containers rodando
docker ps

# Logs de um serviço
docker logs -f security
docker logs -f bff-negocios
docker logs -f nginx

# Reiniciar tudo
docker compose down && docker compose up -d

# Reiniciar só um serviço
docker compose restart security

# Atualizar imagens manualmente
docker compose pull && docker compose up -d

# Limpar imagens antigas
docker image prune -f
```
