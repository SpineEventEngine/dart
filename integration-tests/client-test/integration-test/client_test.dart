/*
 * Copyright 2021, TeamDev. All rights reserved.
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

import 'package:spine_client/client.dart';
import 'package:spine_client/spine/client/query.pb.dart';
import 'package:spine_client/spine_client.dart';
import 'package:spine_client/time.dart';
import 'package:spine_client/uuids.dart';
import 'package:spine_client/web_firebase_client.dart';
import 'package:test/test.dart';

import 'endpoints.dart';
import 'firebase_app.dart';
import 'spine/core/user_id.pb.dart' as testUserId;
import 'spine/web/test/given/commands.pb.dart';
import 'spine/web/test/given/events.pb.dart';
import 'spine/web/test/given/project.pb.dart';
import 'spine/web/test/given/project_progress.pb.dart';
import 'spine/web/test/given/task.pb.dart';
import 'spine/web/test/given/user_tasks.pb.dart';
import 'types.dart' as testTypes;

@TestOn("browser")
void main() {

    group('Client should', () {

        late Clients clients;
        late FirebaseClient firebaseClient;
        late UserId actor;

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

        /// Creates a future which waits for two seconds.
        ///
        /// Tests need for a process on the server to end before sending a query. Since the entity
        /// state update is broadcast before the entity state is stored (by design), we have to way
        /// of knowing when it's safe to make a query. This is not an issue for end-users, since,
        /// if they already create subscriptions, they are not likely to make a query as soon as
        /// an update occurs.
        ///
        Future<void> _sleep() => Future.delayed(Duration(seconds: 2));

        test('send commands and obtain query data through Firebase RDB', () async {
            var taskId = TaskId()
                ..value = newUuid();
            var cmd = CreateTask()
                ..id = taskId
                ..name = 'Task name 1'
                ..description = 'Firebase query test';
            var client = clients.onBehalfOf(actor);
            var request = client.command(cmd);
            var stateSubscription = await client.subscribeTo<Task>()
                                                .whereIdIn([taskId])
                                                .post();
            request.postAndForget();
            await stateSubscription.itemAdded.first;
            await _sleep();
            var tasks = await client.select<Task>()
                                    .post()
                                    .toList();
            expect(tasks, hasLength(greaterThanOrEqualTo(1)));
            var matchingById = tasks.where((task) => task.id == taskId);
            expect(matchingById, hasLength(1));
        });

        test('send commands and subscribe to related events', () async {
            var taskId = TaskId()
                ..value = newUuid();
            var cmd = CreateTask()
                ..id = taskId
                ..name = 'Task name 42'
                ..description = 'Firebase event subscription test';
            var client = clients.onBehalfOf(actor);
            var request = client.command(cmd);
            var futureSubscription = request.observeEvents<TaskCreated>();
            await request.post();

            // Subscription must be complete when `post` is complete.
            var subscription = await futureSubscription;
            var event = await subscription.eventMessages.first;
            expect(event.id, equals(taskId));

            expect(subscription.closed, equals(false));
            subscription.unsubscribe();
            expect(subscription.closed, equals(true));
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
                ..name = 'Task name 2'
                ..description = 'direct query test';

            var client = clients.onBehalfOf(actor);
            var newTasks = await client.subscribeTo<Task>()
                                       .whereIdIn([taskId])
                                       .post();
            client.command(cmd)
                  .postAndForget();
            // Make sure command is processed...
            await newTasks.itemAdded.first;
            // ... and the entity is saved.
            await _sleep();

            var tasks = await clients.asGuest()
                                     .select<Task>()
                                     .whereIds([taskId])
                                     .post()
                                     .toList();
            expect(tasks, hasLength(1));
            expect(tasks[0].id, equals(taskId));
            expect(tasks[0].name, equals(cmd.name));
        });

        test('subscribe to entity changes', () async {
            var client = clients.onBehalfOf(actor);
            StateSubscription<Task> entitySubscription = await client.subscribeTo<Task>().post();
            Stream<Task> itemAdded = entitySubscription.itemAdded;
            var taskId = TaskId()
                ..value = newUuid();
            var createTaskCmd = CreateTask()
                ..id = taskId
                ..name = 'Task name 3'
                ..description = 'subscription test';
            var createTaskRequest = client.command(createTaskCmd);
            var taskCreatedEvents = createTaskRequest.observeEvents<TaskCreated>();
            createTaskRequest.post();

            var newTaskEvent = await taskCreatedEvents.then((s) => s.eventMessages.first);
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

        test('query entities by column values', () async {
            var newTasks = await clients.asGuest()
                                        .subscribeTo<UserTasks>()
                                        .post();
            var client = clients.onBehalfOf(actor);
            var olderTaskId = TaskId()..value = newUuid();
            client.command(CreateTask()
                                ..id = olderTaskId
                                ..name = 'Task name-182'
                                ..description = 'Query by fields test'
                                ..assignee = (testUserId.UserId()..value = newUuid()))
                  .postAndForget();
            var firstTask = newTasks.itemAdded.elementAt(0);
            var secondTask = newTasks.itemAdded.elementAt(1);
            await firstTask;
            var thresholdTime = now();
            client.command(CreateTask()
                                ..id = (TaskId()..value = newUuid())
                                ..name = 'Task name 42'
                                ..description = 'Query by fields test'
                                ..assignee = (testUserId.UserId()..value = newUuid()))
                  .postAndForget();
            await secondTask;
            await _sleep();
            var tasks = await client.select<UserTasks>()
                                    .where(all([lt('last_updated', thresholdTime)]))
                                    .post()
                                    .toList();
            expect(tasks, hasLength(1));
            expect(tasks[0].tasks.first, equals(olderTaskId));
        });

        test('query entities with order and limit', () async {
            var newProjections = await clients.asGuest()
                                              .subscribeTo<UserTasks>()
                                              .post();
            var client = clients.onBehalfOf(actor);
            client.command(CreateTask()
                ..id = (TaskId()..value = newUuid())
                ..name = 'Task name 1'
                ..description = 'Query with limit'
                ..assignee = (testUserId.UserId()..value = newUuid()))
                .postAndForget();
            client.command(CreateTask()
                ..id = (TaskId()..value = newUuid())
                ..name = 'Task name 42'
                ..description = 'Query with limit'
                ..assignee = (testUserId.UserId()..value = newUuid()))
                .postAndForget();
            client.command(CreateTask()
                ..id = (TaskId()..value = newUuid())
                ..name = 'Task name 3.14'
                ..description = 'Query with limit'
                ..assignee = (testUserId.UserId()..value = newUuid()))
                .postAndForget();
            await newProjections.itemAdded.elementAt(2);
            await _sleep();
            var limit = 2;
            var tasks = await client.select<UserTasks>()
                .orderBy('last_updated', OrderBy_Direction.DESCENDING)
                .limit(limit)
                .post()
                .toList();
            expect(tasks, hasLength(limit));
            expect(tasks[0].lastUpdated.seconds,
                   greaterThanOrEqualTo(tasks[0].lastUpdated.seconds));
        });

        test('query entities by enum column values', () async {
            var projectProgress = await clients.asGuest()
                                               .subscribeTo<ProjectProgress>()
                                               .post();
            var client = clients.onBehalfOf(actor);
            var completedProject = ProjectId()..value = newUuid();
            client.command(CreateProject()
                ..id = completedProject)
                .postAndForget();
            var newProjectProgress = projectProgress.itemAdded.first;
            await newProjectProgress;

            var taskToComplete = (TaskId()..value = newUuid());
            client.command(CreateTask()
                ..id = taskToComplete
                ..name = 'Task in the completed project'
                ..project = completedProject)
                .postAndForget();
            var progressUpdate = projectProgress.itemChanged.first;
            await progressUpdate;

            client.command(CompleteTask()
                ..id = taskToComplete)
                .postAndForget();
            await _sleep();

            var completedProjects = await client.select<ProjectProgress>()
                .where(all([eq('status', Status.COMPLETED)]))
                .post()
                .toList();
            var projectsInProgress = await client.select<ProjectProgress>()
                .where(all([eq('status', Status.IN_PROGRESS)]))
                .post()
                .toList();
            expect(completedProjects, hasLength(1));
            expect(projectsInProgress, hasLength(0));
        });
    });
}
