# ==========================================
# 阶段 1：Builder (下载与清理)
# ==========================================
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 1. 下载并精准提取 llama-server
# 使用 */llama-server 应对不同版本解压后文件夹名称的差异
RUN curl -L -o llama.zip https://github.com/ggerganov/llama.cpp/releases/download/b3925/llama-b3925-bin-ubuntu-x64.zip \
    && unzip llama.zip \
    && rm llama.zip \
    && mv */llama-server . \
    && rm -rf */

# 2. 下载 jc-builds 提供的 Q4_K_M 量化模型 (约 90MB)
RUN curl -L -o model.gguf https://huggingface.co/jc-builds/SmolLM2-135M-Instruct-Q4_K_M-GGUF/resolve/main/smollm2-135m-instruct-q4_k_m.gguf


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# ==========================================
FROM debian:bookworm-slim

# 仅安装 C++ 和 OpenMP 运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 从 builder 阶段精准复制清理后的文件
COPY --from=builder /build/llama-server /app/llama-server
COPY --from=builder /build/model.gguf /app/model.gguf
COPY start.sh /app/start.sh

RUN chmod +x /app/llama-server /app/start.sh

EXPOSE 8080
CMD ["/app/start.sh"]
