/*
 * Copyright 2019, TeamDev. All rights reserved.
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

import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.FirebaseDatabase;
import io.spine.io.Resource;
import io.spine.server.BoundedContext;
import io.spine.server.CommandService;
import io.spine.server.QueryService;
import io.spine.server.SubscriptionService;
import io.spine.web.firebase.FirebaseClient;
import io.spine.web.firebase.FirebaseCredentials;
import io.spine.web.firebase.query.FirebaseQueryBridge;
import io.spine.web.firebase.subscription.FirebaseSubscriptionBridge;

import java.io.IOException;

import static com.google.common.base.Preconditions.checkNotNull;
import static io.spine.web.firebase.FirebaseClientFactory.remoteClient;
import static io.spine.web.firebase.FirebaseCredentials.fromGoogleCredentials;

/**
 * A test Spine application.
 */
final class Application {

    private static final String DATABASE_URL = "https://spine-dev.firebaseio.com/";

    private final CommandService commandService;
    private final FirebaseQueryBridge queryBridge;
    private final FirebaseSubscriptionBridge subscriptionBridge;

    private Application(CommandService commandService,
                        QueryService queryService,
                        SubscriptionService subscriptionService,
                        FirebaseClient client) {
        this.commandService = commandService;
        this.queryBridge = FirebaseQueryBridge
                .newBuilder()
                .setQueryService(queryService)
                .setFirebaseClient(client)
                .build();
        this.subscriptionBridge = FirebaseSubscriptionBridge
                .newBuilder()
                .setSubscriptionService(subscriptionService)
                .setFirebaseClient(client)
                .build();
    }

    static Application create(BoundedContext boundedContext) {
        checkNotNull(boundedContext);
        CommandService commandService = CommandService
                .newBuilder()
                .add(boundedContext)
                .build();
        QueryService queryService = QueryService
                .newBuilder()
                .add(boundedContext)
                .build();
        SubscriptionService subscriptionService = SubscriptionService
                .newBuilder()
                .add(boundedContext)
                .build();
        FirebaseClient retryingClient = buildClient();
        return new Application(commandService, queryService, subscriptionService, retryingClient);
    }

    private static FirebaseClient buildClient() {
        Resource googleCredentialsFile = Resource.file("spine-dev.json");

        // Same credentials but represented with different Java objects.
        GoogleCredentials credentials;
        GoogleCredential credential;
        try {
            credentials = GoogleCredentials.fromStream(googleCredentialsFile.open());
            credential = GoogleCredential.fromStream(googleCredentialsFile.open());
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
        FirebaseOptions options = FirebaseOptions
                .builder()
                .setDatabaseUrl(DATABASE_URL)
                .setCredentials(credentials)
                .build();
        FirebaseApp.initializeApp(options);

        FirebaseDatabase database = FirebaseDatabase.getInstance();
        FirebaseCredentials firebaseCredentials = fromGoogleCredentials(credential);
        FirebaseClient firebaseClient = remoteClient(database, firebaseCredentials);
        return new TidyClient(firebaseClient);
    }

    CommandService commandService() {
        return commandService;
    }

    FirebaseQueryBridge queryBridge() {
        return this.queryBridge;
    }

    FirebaseSubscriptionBridge subscriptionBridge() {
        return this.subscriptionBridge;
    }
}
