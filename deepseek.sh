#------------------------------------------------------------
### Set up Deepseek agents locally on Debian 13 cheapest tokens
# Hardware reality check!
# Model (Ollama tag),Approx. size,RAM / VRAM needed (Q4),Notes
# deepseek-r1:1.5b,~1–2 GB,4–8 GB,"Fast, basic"
# deepseek-r1:7b / :8b,~5 GB,8–16 GB,Sweet spot for most machines
# deepseek-r1:14b,~9 GB,16–24 GB,Better reasoning
# deepseek-r1:32b,~20 GB,24–40 GB,Strong
# Full R1 / V3 / V4 (671B+),Hundreds of GB,Multi-GPU / 128+ GB RAM,Not “cheap” hardware

# Base system prep (Debian 13)
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential python3 python3-pip python3-venv htop

## NVIDIA GPU:
sudo apt install -y nvidia-driver nvidia-cuda-toolkit
# verify nvidia has CUDA capabilities
nvidia-smi

## Install Ollama
curl -fsSL https://ollama.com/install.sh | sh
ollama --version
systemctl status ollama   # should be active

## Pull and run a Deepseek model
# Start with the balanced choice
ollama pull deepseek-r1:8b
# or smaller/faster
ollama pull deepseek-r1:7b
# or larger if you have the VRAM/RAM
ollama pull deepseek-r1:14b

# Test the model
ollama run deepseek-r1:8b

## Nice web UI (optional but useful for agents)
python3 -m venv ~/open-webui
source ~/open-webui/bin/activate
pip install open-webui
open-webui serve

## If errors were encountered while processing:
# /tmp/apt-dpkg-install-To068T/06-docker-buildx_0.13.1+ds1-3_amd64.deb
# Error: Sub-process /usr/bin/dpkg returned an error code (1)

# Purge the half-installed Debian packages
sudo apt remove -y docker.io docker-buildx docker-cli containerd runc 2>/dev/null || true
sudo apt autoremove -y
sudo dpkg --configure -a

# Re-add Docker’s official repo (if it was removed) and install
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# log out / newgrp docker, then test
docker --version
docker run hello-world

# Once Docker works, run the Open WebUI container
docker run -d \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  ghcr.io/open-webui/open-webui:main

## If "No models available" make Ollama listen on all interfaces
# In a browser, open http://localhost:3000.
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama

# Verify it is now listening correctly
ss -tlnp | grep 11434
# or
curl http://localhost:11434/api/tags

# Restart the Open WebUI container
docker restart open-webui

# Alternative fix for "no models available"
docker stop open-webui
docker rm open-webui

docker run -d \
  --network=host \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  ghcr.io/open-webui/open-webui:main

#------------------------------------------------------------
### In the future, for production-style serving (higher throughput, better concurrent agents) switch later to vLLM:
pip install vllm
vllm serve deepseek-ai/DeepSeek-R1-Distill-Qwen-14B --port 8000 ...
