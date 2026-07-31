# ==========================================
# 阶段 1：Builder (下载与清理)
# ==========================================
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 下载并解压 llama-server，仅保留核心二进制文件
RUN curl -L -o llama.zip https://github.com/ggerganov/llama.cpp/releases/download/b3925/llama-b3925-bin-ubuntu-x64.zip \
    && unzip llama.zip \
    && rm llama.zip \
    && find . -mindepth 1 -maxdepth 1 ! -name "llama-server" -exec rm -rf {} +

# 下载 SmolLM2-135M 的 4-bit 量化模型
RUN curl -L -o model.gguf https://huggingface.co/HuggingFaceTB/smollm2-135m-instruct-Q4_K_M-GGUF/resolve/main/smollm2-135m-instruct-q4_k_m.gguf


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# ==========================================
FROM debian:bookworm-slim

# 仅安装运行 C++ 程序必需的最小依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 精准复制所需文件
COPY --from=builder /build/llama-server /app/llama-server
COPY --from=builder /build/model.gguf /app/model.gguf
COPY start.sh /app/start.sh

RUN chmod +x /app/llama-server /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
