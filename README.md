# Spring Cloud Function を使って、AWS Lambda 関数を native-image で作る
以下を参考にサンプルを作る

[Spring Native の Getting Started](https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/#getting-started)

[Spring Native の Spring Cloud Function AWS のサンプル](https://github.com/spring-projects-experimental/spring-graalvm-native/tree/master/spring-graalvm-native-samples/cloud-function-aws)

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

* Getting Started の [Getting started with native image Maven plugin](https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/#getting-started-native-image) を参考に記述
* 必要なファイル群を配置
* `profiles.profile.build.plugins.plugin.configuration.mainClass` の指定を間違えないように注意

## サンプルとなる関数を追加

* 以前に作ったサンプルと同じモノを使う

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
RUN yum install -y gcc zlib-devel libstdc++-static glibc-devel

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

Docker Image を起動。ログイン。

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

### ビルドする

Docker Image へログイン（8GB以上のメモリが必要なので、メモリを指定する）

```shell
docker run --memory=8g -v "$(pwd)":/work/build --rm -it awslambda-native-builder:latest /bin/bash
```

ビルド

```shell
mvn -Pnative-image clean package -Dmaven.test.skip=true
```

ビルド成功。

### 実行してみる

ポートを開ける必要があるので、下記コマンドで Docker Image に再ログイン

```shell
docker run --memory=8g -v "$(pwd)":/work/build -p 8080:8080 --rm -it awslambda-native-builder:latest /bin/bash
```

下記コマンドで実行

```shell
./target/com.myexample.serverless.greetapplication
```

起動した。
その後、別ターミナルから、

```
curl -H "Content-Type: application/json" localhost:8080/greet -d '{"name": "AAA", "message": "Hello"}'
```

を実行し、返値が返ることを確認

### 注意点
* 関数の入口となるクラスに `@Component` を付与したこと。これで、Cloud Function から認識されるようになった。
* 起動は遅くなる。ApplicationContextInitializer を利用したいところ
  
### AWS Lambda へデプロイ

bootstrap と併せて zip ファイルを作成し、AWS Lambda のカスタムランタイムとして登録

```
chmod 775 ./src/shell/bootstrap
zip -j ./src/shell/bootstrap ./target/com.myexample.serverless.greetapplication
```

ハンドラは、`greet` とする

AWS Lambda のテストで、以下のメッセージを投げるテスト

```
{"name": "AAA", "message": "Hello"}
```

###  注意点

* `pom.xml` の `buildArgs` に　`--enable-http` と `--enable-https` を追加
* 上記を追記したら、 `libstdc++` が必要と言われたので Dockerfile に追加




