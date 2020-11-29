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

