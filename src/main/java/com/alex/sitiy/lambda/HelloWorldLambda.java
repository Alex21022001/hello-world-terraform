package com.alex.sitiy.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import org.jboss.logging.Logger;

import java.util.Map;

public class HelloWorldLambda implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {

    private static final Logger LOGGER = Logger.getLogger(HelloWorldLambda.class);

    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context) {
        LOGGER.info(event);

        String body;
        if (event.getQueryStringParameters() != null && event.getQueryStringParameters().get("Name") != null) {
            body = "Hello " + event.getQueryStringParameters().get("Name");
        } else {
            body = "Hello everyone";
        }

        return APIGatewayV2HTTPResponse.builder()
                .withStatusCode(200)
                .withHeaders(Map.of("Content-Type", "application/json"))
                .withBody(body)
                .build();
    }
}
