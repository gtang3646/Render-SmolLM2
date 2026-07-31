# ==========================================
# 阶段 1：Builder (下载与清理)
# 强制指定平台为 linux/amd64，确保与 Render 的 x86_64 服务器完全匹配
# ==========================================
FROM --platform=linux/amd64 debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 1. 下载、解压，并精准提取 llama-server，然后清理残留目录
RUN curl -L -o llama.zip https://github.com/ggerganov/llama.cpp/releases/download/b3925/llama-b3925-bin-ubuntu-x64.zip \
    && unzip llama.zip \
    && rm llama.zip \
    && cp build/bin/llama-server . \
    && rm -rf build

# 2. 下载 jc-builds 提供的 Q4_K_M 量化模型 (约 90MB)
RUN curl -L -o model.gguf https://huggingface.co/jc-builds/SmolLM2-135M-Instruct-Q4_K_M-GGUF/resolve/main/smollm2-135m-instruct-q4_k_m.gguf


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# 同样强制指定平台为 linux/amd64
# ==========================================
FROM --platform=linux/amd64 debian:bookworm-slim

# 核心修复：补全 llama-server 运行所需的所有动态链接库
# libgomp1: OpenMP 多线程支持
# libstdc++6: C++ 标准库
# libcurl4: 网络请求库 (llama-server 强依赖)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libstdc++6 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 从 builder 阶段精准复制清理后的文件
COPY --from=builder /build/llama-server /app/llama-server
COPY --from=builder /build/model.gguf /app/model.gguf
COPY start.sh /app/start.sh

# 修复 Windows 换行符并赋予执行权限
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/llama-server /app/start.sh

EXPOSE 8080
CMD ["/app/start.sh"]
