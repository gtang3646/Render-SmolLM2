# 使用轻量级基础镜像
FROM debian:bookworm-slim

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    wget \
    nginx \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 克隆 llama.cpp
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git

# 编译 llama.cpp（CPU 优化）
RUN cd llama.cpp && \
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_NATIVE=OFF \
        -DLLAMA_AVX2=ON \
        -DLLAMA_AVX=ON \
        -DLLAMA_SSE42=ON && \
    cmake --build build --config Release -j$(nproc)

# 下载 SmolLM2-135M Q4_K_M 模型
RUN mkdir -p /app/models && \
    wget -q -O /app/models/SmolLM2-135M-Instruct-Q4_K_M.gguf \
    "https://huggingface.co/HuggingFaceTB/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q4_K_M.gguf"

# 复制配置文件
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 创建 nginx 所需目录
RUN mkdir -p /var/log/nginx /var/run /var/lib/nginx

# 暴露 Render 要求的端口
EXPOSE 10000

# 启动服务
CMD ["/app/start.sh"]
