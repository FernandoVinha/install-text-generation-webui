#!/bin/bash

# Atualização do sistema e drivers
echo "Atualizando sistema e drivers..."
sudo apt update
sudo ubuntu-drivers autoinstall
sudo reboot

# Após reiniciar, continuar com a instalação do Docker
echo "Instalando Docker e Docker Compose..."
sudo apt-get install curl
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER
newgrp docker

# Instalar NVIDIA Docker para suporte a GPU
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/ubuntu22.04/amd64 /" | sudo tee /etc/apt/sources.list.d/nvidia.list > /dev/null
sudo apt update
sudo apt install nvidia-docker2 nvidia-container-runtime -y
sudo systemctl restart docker

# Detectar a placa de vídeo NVIDIA e ajustar a variável TORCH_CUDA_ARCH_LIST
GPU_ARCH=$(lspci | grep -i nvidia | cut -d ' ' -f 1 | xargs -I{} lspci -v -s {} | grep 'Kernel modules' | cut -d ':' -f 2 | tr -d ' ')
echo "Placa de vídeo detectada: $GPU_ARCH"

# Clonar o repositório e preparar ambiente
echo "Clonando o repositório text-generation-webui..."
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui
ln -s docker/{nvidia/Dockerfile,docker-compose.yml,.dockerignore} .
cp docker/.env.example .env

# Editar o arquivo .env automaticamente
echo "Configurando o arquivo .env..."
sed -i "s/#TORCH_CUDA_ARCH_LIST=/TORCH_CUDA_ARCH_LIST=$GPU_ARCH/" .env
echo "MODEL_NAME=GPTQ-for-LLaMa" >> .env
echo "GPU_ENABLED=true" >> .env

# Configurar o uso do modelo GPTQ-for-LLaMa
echo "Configurando o modelo GPTQ-for-LLaMa no Docker Compose..."
sed -i 's/MODELO_ANTIGO/GPTQ-for-LLaMa/g' docker-compose.yml

# Iniciar o Docker Compose
echo "Iniciando o Docker Compose..."
docker compose up --build

echo "Instalação e configuração concluídas. Acesse a interface web em http://localhost:5000"

