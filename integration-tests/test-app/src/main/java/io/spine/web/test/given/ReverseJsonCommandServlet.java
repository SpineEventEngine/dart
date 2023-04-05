/*
 * Copyright 2023, TeamDev. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Redistribution and use in source and/or binary forms, with or without
 * modification, must retain the above copyright notice and the following
 * disclaimer.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package io.spine.web.test.given;

import com.google.common.net.MediaType;
import io.spine.core.Ack;
import io.spine.core.Command;
import io.spine.web.command.CommandServlet;
import io.spine.web.parser.MessageFormat;

import javax.servlet.ServletRequest;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Optional;

import static io.spine.json.Json.toCompactJson;
import static io.spine.web.test.given.Server.application;
import static java.util.stream.Collectors.joining;
import static javax.servlet.http.HttpServletResponse.SC_BAD_REQUEST;

/**
 * Handles {@code Command}s sent via HTTP.
 *
 * <p>Takes and returns Proto messages written as JSON strings,
 * same as regular, but with their characters in reverse order.
 */
@WebServlet("/reverse-json-command")
@SuppressWarnings("serial")
public final class ReverseJsonCommandServlet extends CommandServlet {

    /**
     * Same as {@link MediaType#JSON_UTF_8}, but the symbols of JSON message are reversed.
     */
    private static final MediaType REVERSE_JSON_TYPE =
            MediaType.create("application", "reversed-json");

    public ReverseJsonCommandServlet() {
        super(application().commandService());
    }

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Optional<Command> optionalMessage = parseRequest(req);
        if (!optionalMessage.isPresent()) {
            resp.sendError(SC_BAD_REQUEST);
        } else {
            Command message = optionalMessage.get();
            Ack response = handle(message);
            writeResponse(resp, response);
        }
    }

    private static void writeResponse(HttpServletResponse response, Ack ack)
            throws IOException {
        String json = toCompactJson(ack);
        String reversed = reverse(json);
        response.getWriter()
                .append(reversed);
        response.setContentType(REVERSE_JSON_TYPE.toString());
    }

    private static String reverse(String input) {
        return new StringBuilder(input).reverse()
                                       .toString();
    }

    private static Optional<Command> parseRequest(HttpServletRequest req) throws IOException {
        String body = body(req);
        String toParse = reverse(body);
        Optional<Command> result = MessageFormat.JSON.parse(toParse, Command.class);
        return result;
    }

    private static String body(ServletRequest request) throws IOException {
        String result = request.getReader()
                               .lines()
                               .collect(joining(" "));
        return result;
    }
}
