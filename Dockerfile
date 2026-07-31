# ==========================================
# 阶段 1：Builder (下载与清理)
# 使用 ubuntu:24.04 以匹配 llama.cpp 官方预编译二进制文件的 glibc 依赖
# ==========================================
FROM --platform=linux/amd64 ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
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

# 2. 下载 bartowski 提供的可靠 Q4_K_M 量化模型 (约 105MB)
# 修复：使用真实有效的链接，避免下载到 HTML 错误页面
RUN curl -L -o model.gguf https://huggingface.co/bartowski/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q4_K_M.gguf


# ==========================================
# 阶段 2：Runtime (极简运行环境)
# 同样使用 ubuntu:24.04 确保 glibc 版本完全匹配
# ==========================================
FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装 llama-server 运行所需的动态链接库
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
