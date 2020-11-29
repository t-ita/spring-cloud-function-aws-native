package com.myexample.serverless.functions;

import lombok.Data;

import java.util.function.Function;

public class Greet implements Function<Greet.Greeting, Greet.Greeting> {

    @Data
    public static class Greeting {
        String name;
        String message;
    }

    @Override
    public Greeting apply(Greeting greeting) {
        var res = new Greeting();
        res.name = "Spring Cloud Function - native image on AWS Lambda";
        res.message = String.format("%s, %s", greeting.message, greeting.name);
        return res;
    }

}
