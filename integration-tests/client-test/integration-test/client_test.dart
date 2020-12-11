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

import 'package:spine_client/client.dart';
import 'package:spine_client/spine_client.dart';
import 'package:spine_client/uuids.dart';
import 'package:spine_client/web_firebase_client.dart';
import 'package:test/test.dart';

import 'endpoints.dart';
import 'firebase_app.dart';
import 'spine/web/test/given/commands.pb.dart';
import 'spine/web/test/given/events.pb.dart';
import 'spine/web/test/given/task.pb.dart';
import 'types.dart' as testTypes;

@TestOn("browser")
void main() {

    group('Client should', () {
        Clients clients;
        FirebaseClient firebaseClient;
        UserId actor;

        setUp(() {
            var database = FirebaseApp().database;
            firebaseClient = WebFirebaseClient(database);
            clients = Clients(BACKEND,
                              firebase: firebaseClient,
                              typeRegistries: [testTypes.types()]);
            actor = UserId()..value = 'Dart-integration-tests';
        });

        tearDown(() {
            clients.cancelAllSubscriptions();
        });

        test('send commands and obtain query data', () async {
            var taskId = TaskId()
                ..value = newUuid();
            var cmd = CreateTask()
                ..id = taskId
                ..name = 'Task name'
                ..description = "long";
            var client = clients.onBehalfOf(actor);
            var request = client.command(cmd);
            var events = request.observeEvents(TaskCreated());
            request.post();
            await events.first;
            var tasks = await client.select(Task())
                                    .post()
                                    .toList();
            expect(tasks, hasLength(greaterThanOrEqualTo(1)));
            var matchingById = tasks.where((task) => task.id == taskId);
            expect(matchingById, hasLength(1));
        });

        test('query server directly', () async {
            clients = Clients(BACKEND,
                              queryMode: QueryMode.DIRECT,
                              firebase: firebaseClient,
                              endpoints: Endpoints(
                                  query: 'direct-query'
                              ));
            var taskId = TaskId()
                ..value = newUuid();
            var cmd = CreateTask()
                ..id = taskId
                ..name = 'Task name'
                ..description = "long";
            var commandRequest = clients.onBehalfOf(actor)
                                        .command(cmd);
            var events = commandRequest.observeEvents(TaskCreated());
            commandRequest.post();
            await events.first;
            var tasks = await clients.asGuest()
                                     .select(Task())
                                     .post()
                                     .toList();
            expect(tasks, hasLength(greaterThanOrEqualTo(1)));
            var matchingById = tasks.where((task) => task.id == taskId);
            expect(matchingById, hasLength(1));
        });

        test('subscribe to entity changes', () async {
            var client = clients.onBehalfOf(actor);
            StateSubscription<Task> entitySubscription =
                    client.subscribeTo(Task())
                          .post();
            Stream<Task> itemAdded = entitySubscription.itemAdded;
            var taskId = TaskId()
                ..value = newUuid();
            var createTaskCmd = CreateTask()
                ..id = taskId
                ..name = 'Task name'
                ..description = "long";
            var createTaskRequest = client.command(createTaskCmd);
            var taskCreatedEvents = createTaskRequest.observeEvents(TaskCreated());
            createTaskRequest.post();

            var newTaskEvent = await taskCreatedEvents.first;
            expect(newTaskEvent.id, equals(taskId));
            var newTask = await itemAdded.first;
            expect(newTask.name, equals(createTaskCmd.name));

            Stream<Task> itemChanged = entitySubscription.itemChanged;
            var renameTaskCmd = RenameTask()
                ..id = taskId
                ..name = 'New task name';
            client.command(renameTaskCmd)
                  .postAndForget();

            var changedTask = await itemChanged.first;
            expect(changedTask.name, equals(renameTaskCmd.name));
            entitySubscription.unsubscribe();
        });
    });
}
