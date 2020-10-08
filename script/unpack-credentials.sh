#!/bin/bash

#
# Copyright 2020, TeamDev. All rights reserved.
#
# Redistribution and use in source and/or binary forms, with or without
# modification, must retain the above copyright notice and the following
# disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Decrypt and unpack credentials:
#  - spine-dev.json - the Firebase service account to use for integration tests;
#  - pub-credentials.json - credentials to publish package to Pub;
#  - deploy_rsa_key - private key for deploying GitHub Pages.
openssl aes-256-cbc -K $encrypted_54891cbed47a_key -iv $encrypted_54891cbed47a_iv -in credentials.tar.enc -out credentials.tar -d
tar xvf credentials.tar
mkdir ./integration-tests/test-app/src/main/resources
mv ./spine-dev-firebase.json ./integration-tests/test-app/src/main/resources
mv ./pub-credentials.json "$HOME"/.pub-cache/credentials.json
