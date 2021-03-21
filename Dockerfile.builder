FROM amazonlinux:2

SHELL ["/bin/bash", "-c"]
RUN yum update -y

# SDKMAN を利用して、GraalVM、GraalVM Native Image 拡張、Maven をインストール
RUN yum install -y which unzip zip gzip tar
RUN curl -s "https://get.sdkman.io" | bash; \
    source "$HOME/.sdkman/bin/sdkman-init.sh"; \
    sdk install java 21.0.0.r11-grl; \
    gu install native-image; \
    sdk install maven

# Native Image 構築に必要なライブラリをインストール
RUN yum install -y gcc zlib-devel libstdc++-static glibc-devel

# 依存性を Docker Image にダウンロード
COPY pom.xml /work/build/
WORKDIR /work/build
RUN source "$HOME/.sdkman/bin/sdkman-init.sh"; \
    mvn dependency:go-offline
