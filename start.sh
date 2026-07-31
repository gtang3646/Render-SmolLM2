#!/bin/sh

# 动态读取环境变量，适配 Render 和本地运行
API_KEY=${API_KEY:-"sk-default-secret-key"}
PORT=${PORT:-8080}

echo "Starting SmolLM2 API on port $PORT with API Key auth..."

exec /app/llama-server \
  -m /app/model.gguf \
  --host 0.0.0.0 \
  --port $PORT \
  --api-key "$API_KEY" \
  -c 256 \
  -t 1 \
  --parallel 1 \
  --no-mmap \
  --log-disable
