# ==========================================
# 阶段 1：Builder (下载与清理)
# ==========================================
FROM debian:bookworm-slim AS builder

# 仅安装下载工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 1. 下载最新版本的 llama.cpp 预编译二进制文件 
# (注意：官方仓库已迁移至 ggml-org，且格式为 .tar.gz。这里使用稳定的 b10212 版本)
RUN curl -L -o llama.tar.gz https://github.com/ggml-org/llama.cpp/releases/download/b10212/llama-b10212-bin-ubuntu-x64.tar.gz \
    && tar -xzf llama.tar.gz \
    && rm llama.tar.gz \
    # 2. 智能提取：全局查找名为 "llama-server" 的文件，移动到 /build 根目录，然后清空其他所有解压垃圾
    && find . -type f -name "llama-server" -exec mv {} /build/llama-server \; \
    && rm -rf ./*

# 3. 下载 SmolLM2-135M 的 4-bit 量化模型
RUN curl -L -o model.gguf https://huggingface.co/HuggingFaceTB/smollm2-135m-instruct-Q4_K_M-GGUF/resolve/main/smollm2-135m-instruct-q4_k_m.gguf


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# ==========================================
FROM debian:bookworm-slim

# 仅安装运行 C++ 程序必需的最小动态链接库
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 精准复制所需文件（此时 builder 阶段只有 llama-server 和 model.gguf）
COPY --from=builder /build/llama-server /app/llama-server
COPY --from=builder /build/model.gguf /app/model.gguf
COPY start.sh /app/start.sh

RUN chmod +x /app/llama-server /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
