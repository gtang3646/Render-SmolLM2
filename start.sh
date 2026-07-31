#!/bin/bash
set -e

echo "=== Starting SmolLM2-135M on Render ==="

# 设置 API Key（从环境变量读取，或使用默认值）
API_KEY="${API_KEY:-sk-smollm2-render-default-key}"

echo "API Key configured: ${API_KEY:0:10}..."

# 替换 nginx 配置中的 API Key
sed -i "s|__API_KEY__|$API_KEY|g" /etc/nginx/nginx.conf

# 启动 llama.cpp server（后台运行）
echo "Starting llama.cpp server..."
/app/llama.cpp/build/bin/llama-server \
    -m /app/models/SmolLM2-135M-Instruct-Q4_K_M.gguf \
    -c 128 \
    -n 256 \
    -t 2 \
    -b 1 \
    --parallel 1 \
    --host 127.0.0.1 \
    --port 8080 \
    --no-webui \
    --metrics &

LLAMA_PID=$!

# 等待 llama.cpp 启动
sleep 5

# 检查是否成功启动
if ! kill -0 $LLAMA_PID 2>/dev/null; then
    echo "ERROR: llama.cpp server failed to start"
    exit 1
fi

echo "llama.cpp server started (PID: $LLAMA_PID)"

# 启动 nginx（前台运行，保持容器活跃）
echo "Starting nginx..."
nginx -g 'daemon off;'
