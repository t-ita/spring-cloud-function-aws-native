# Spring Cloud Function を使って、AWS Lambda 関数を native-image で作る
以下を参考にサンプルを作る
https://github.com/spring-projects-experimental/spring-graalvm-native/tree/master/spring-graalvm-native-samples/cloud-function-aws

## Spring Initializr でプロジェクトを作成
* Group `com.example`
* Artifact `spring-cloud-function-aws-native`
* Maven プロジェクトで作成
* Java 11 を指定
* Spring Boot のバージョンは 2.4
* Dependencies は以下を指定
    * Developer Tools > Spring Boot DevTools
    * Developer Tools > Lombok

## pom.xml を編集
* 上記サンプルと同じ記述にする（一部、要不要がわからないので）
* 必要なファイル群を配置
* コンパイルで利用する Script を追加

## サンプルとなる関数を追加
* 以前に作ったサンプルと同じモノを使う

## build を実行
* `./build.sh` を実行
* 1回目は失敗。エラーは以下。
```
Error: Main entry point class 'com.myexample.serverless.GreetApplication' not found.
Error: Use -H:+ReportExceptionStackTraces to print stacktrace of underlying exception
Error: Image build request failed with exit status 1
com.oracle.svm.driver.NativeImage$NativeImageError: Image build request failed with exit status 1
        at com.oracle.svm.driver.NativeImage.showError(NativeImage.java:1647)
        at com.oracle.svm.driver.NativeImage.build(NativeImage.java:1397)
        at com.oracle.svm.driver.NativeImage.performBuild(NativeImage.java:1358)
        at com.oracle.svm.driver.NativeImage.main(NativeImage.java:1317)
        at com.oracle.svm.driver.NativeImage$JDK9Plus.main(NativeImage.java:1829)
```
* compile.sh の ARTIFACT の指定に誤りがあったので修正。
* 2回目失敗。エラーは以下。
```
Error: Classes that should be initialized at run time got initialized during image building:
 org.springframework.util.unit.DataSize was unintentionally initialized at build time. To see why org.springframework.util.unit.DataSize got initialized use --trace-class-initialization=org.springframework.util.unit.DataSize

Error: Use -H:+ReportExceptionStackTraces to print stacktrace of underlying exception
Error: Image build request failed with exit status 1
com.oracle.svm.driver.NativeImage$NativeImageError: Image build request failed with exit status 1
        at com.oracle.svm.driver.NativeImage.showError(NativeImage.java:1647)
        at com.oracle.svm.driver.NativeImage.build(NativeImage.java:1397)
        at com.oracle.svm.driver.NativeImage.performBuild(NativeImage.java:1358)
        at com.oracle.svm.driver.NativeImage.main(NativeImage.java:1317)
        at com.oracle.svm.driver.NativeImage$JDK9Plus.main(NativeImage.java:1829)
```
#　再度、ドキュメントの Getting Started からやり直し

※下記を参照する

https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/

## pom.xml を編集

* `profiles.profile.build.plugins.plugin.configuration.mainClass` の指定を間違えないように注意

## Docker ファイルを準備

Amazon Linux で動かす必要があるので、Amazon Linux イメージ上でコンパイルするための Docker イメージを準備する。

```dockerfile
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
RUN yum install -y gcc zlib-devel

# 依存性を Docker Image にダウンロード
COPY pom.xml /work/build/
WORKDIR /work/build
RUN source "$HOME/.sdkman/bin/sdkman-init.sh"; \
    mvn dependency:go-offline
```

上記を用意して build

```shell
docker build -f Dockerfile.builder -t awslambda-native-builder:latest .
```

### java / mvn がインストールされていることを確認

```shell
docker run --name builder --rm -it awslambda-native-builder:latest /bin/bash
```

上記コマンドで Docker コンテナを起動しログイン。下記コマンドで確認。

```
bash-4.2# echo $PATH
/root/.sdkman/candidates/maven/current/bin:/root/.sdkman/candidates/java/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
bash-4.2# echo $JAVA_HOME
/root/.sdkman/candidates/java/current
bash-4.2# java -version
openjdk version "11.0.10" 2021-01-19
OpenJDK Runtime Environment GraalVM CE 21.0.0 (build 11.0.10+8-jvmci-21.0-b06)
OpenJDK 64-Bit Server VM GraalVM CE 21.0.0 (build 11.0.10+8-jvmci-21.0-b06, mixed mode, sharing)
bash-4.2# mvn -v
Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
Maven home: /root/.sdkman/candidates/maven/current
Java version: 11.0.10, vendor: GraalVM Community, runtime: /root/.sdkman/candidates/java/21.0.0.r11-grl
Default locale: en_US, platform encoding: ANSI_X3.4-1968
OS name: "linux", version: "4.19.121-linuxkit", arch: "amd64", family: "unix"
bash-4.2# 
```

無事インストールできた様子。

### ビルドしてみる
ログイン

```shell
docker run --memory=8g -v "$(pwd)":/work/build --rm -it awslambda-native-builder:latest /bin/bash
```

ビルド

```shell
mvn -Pnative-image clean package -Dmaven.test.skip=true
```

ビルド成功。




