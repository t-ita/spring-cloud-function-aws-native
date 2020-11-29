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


