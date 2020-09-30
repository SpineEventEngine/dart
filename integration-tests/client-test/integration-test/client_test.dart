/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import 'package:spine_client/spine_client.dart';
import 'package:spine_client/uuids.dart';
import 'package:spine_client/web_firebase_client.dart';
import 'package:test/test.dart';

import 'endpoints.dart';
import 'firebase_app.dart';
import 'spine/web/test/given/commands.pb.dart';
import 'spine/web/test/given/task.pb.dart';
import 'types.dart' as testTypes;

@TestOn("browser")
void main() {

    group('BackendClient should', () {
        ActorRequestFactory requestFactory;
        BackendClient client;

        setUp(() {
            var database = FirebaseApp().database;
            var firebase = WebFirebaseClient(database);
            client = BackendClient(BACKEND, firebase, typeRegistries: [testTypes.types()]);
            var actor = UserId();
            actor.value = newUuid();
            requestFactory = ActorRequestFactory(actor);
        });

        test('send commands and obtain query data', () async {
            var taskId = TaskId()
                ..value = newUuid();
            var cmd = CreateTask()
                ..id = taskId
                ..name = 'Task name'
                ..description = "long";
            await client.post(requestFactory.command().create(cmd));
            var query = requestFactory.query().all(Task());
            var tasks = await client.fetch<Task>(query).toList();
            expect(tasks, hasLength(greaterThanOrEqualTo(1)));
            var matchingById = tasks.where((task) => task.id == taskId);
            expect(matchingById, hasLength(1));
        });

        test('subscribe to entity changes', () async {
            // Subscribe to the `Task` changes.
            var topic = requestFactory.topic().all(Task());
            Subscription<Task> entitySubscription = await client.subscribeTo(topic);

            // Listen to the `itemAdded` event.
            var taskName = "";
            Stream<Task> itemAdded = entitySubscription.itemAdded;
            itemAdded.listen((task) => taskName = task.name);
            var taskId = TaskId()
                ..value = newUuid();

            // Send `CreateTask` command.
            var createTaskCmd = CreateTask()
                ..id = taskId
                ..name = 'Task name'
                ..description = "long";
            await client.post(requestFactory.command().create(createTaskCmd));

            // Check the event is actually fired.
            expect(taskName, equals(createTaskCmd.name));

            // Listen to the `itemChanged` event.
            var newTaskName = "";
            Stream<Task> itemChanged = entitySubscription.itemChanged;
            itemChanged.listen((task) => newTaskName = task.name);

            // Send the `RenameTask` command.
            var renameTaskCmd = RenameTask()
                ..id = taskId
                ..name = 'New task name';
            await client.post(requestFactory.command().create(renameTaskCmd));

            // Verify the event is actually fired.
            expect(newTaskName, equals(renameTaskCmd.name));

            entitySubscription.unsubscribe();
        });
    });
}
