#!/bin/bash
# 启动 llama-server，使用环境变量注入的 PORT 和 API_KEY

./llama-server \
  -m /app/model.gguf \
  --host 0.0.0.0 \
  --port $PORT \
  --api-key "$API_KEY" \
  -c 256 \
  -t 1 \
  --parallel 1 \
  --no-mmap \
  --log-disable
