# ==========================================
# 阶段 1：Builder (下载与清理)
# ==========================================
FROM --platform=linux/amd64 ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 1. 定义构建时环境变量，并提供一个默认值（以防本地构建时未传入）
ARG MODEL_URL=https://huggingface.co/bartowski/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q4_K_M.gguf

# 2. 下载并提取 llama-server
RUN curl -L -o llama.zip https://github.com/ggerganov/llama.cpp/releases/download/b3925/llama-b3925-bin-ubuntu-x64.zip \
    && unzip llama.zip \
    && rm llama.zip \
    && cp build/bin/llama-server . \
    && rm -rf build

# 3. 使用 ARG 变量下载模型
RUN echo "Downloading model from: $MODEL_URL" \
    && curl -L -o model.gguf "$MODEL_URL"


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# ==========================================
FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libstdc++6 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/llama-server /app/llama-server
COPY --from=builder /build/model.gguf /app/model.gguf
COPY start.sh /app/start.sh

RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/llama-server /app/start.sh

EXPOSE 8080
CMD ["/app/start.sh"]
