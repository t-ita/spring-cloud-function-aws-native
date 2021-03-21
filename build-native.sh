#!/bin/bash

docker run --memory=8g -v "$(pwd)":/work/build -p 8080:8080 --rm -it awslambda-native-builder:latest /bin/bash << EOF
mvn -Pnative-image clean package -Dmaven.test.skip=true
chmod 775 ./src/shell/bootstrap
zip ./target/greetapplication -j ./src/shell/bootstrap ./target/com.myexample.serverless.greetapplication
EOF
