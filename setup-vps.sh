#!/bin/bash
# =============================================================
# Setup da VPS para deploy dos microsserviços
# Testado em: Ubuntu 22.04+ (UOL Host)
# =============================================================
#
# Pré-requisitos do servidor:
#   - Ubuntu 22.04 ou superior
#   - Acesso root via SSH
#   - Portas abertas no painel do provedor: 22 (SSH), 80 (HTTP), 443 (HTTPS)
#
# O que este script faz:
#   1. Atualiza o sistema
#   2. Instala Docker + Docker Compose plugin
#   3. Cria o diretório /opt/apps/ (onde ficam os arquivos de deploy)
#   4. Configura o firewall (UFW) liberando SSH, HTTP e HTTPS
#
# Uso:
#   ssh root@SEU_IP
#   curl -fsSL https://raw.githubusercontent.com/code-express-project/deploy/main/setup-vps.sh | bash
#
# Após rodar este script:
#   1. Copie os arquivos para o servidor:
#      scp docker-compose.yml nginx.conf .env root@SEU_IP:/opt/apps/
#
#   2. Configure a chave SSH para o GitHub Actions:
#      - Na máquina local: ssh-keygen -t ed25519 -C "github-actions"
#      - Copie para o servidor: ssh-copy-id -i ~/.ssh/id_ed25519.pub root@SEU_IP
#      - Use a chave PRIVADA (~/.ssh/id_ed25519) como secret SERVER_SSH_KEY no GitHub
#
#   3. Suba os containers:
#      cd /opt/apps && docker compose up -d
#
# =============================================================

set -e

echo ">>> Atualizando sistema..."
apt update && apt upgrade -y

echo ">>> Instalando Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker

echo ">>> Verificando Docker Compose..."
docker compose version

echo ">>> Criando diretório de deploy..."
mkdir -p /opt/apps

echo ">>> Configurando firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo ">>> Setup concluído!"
echo "Próximo passo: copie docker-compose.yml, nginx.conf e .env para /opt/apps/"
