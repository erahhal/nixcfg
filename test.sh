#!/usr/bin/env bash

metatron curl -v -X POST -H 'accept: text/event-stream' -H 'content-type: application/json' -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user", "content":"Hello, whats your name"}],"stream":true}' -a wall_e https://chatapi.test.netflix.net:7004/chat/completion
# metatron curl -v -X POST -H 'accept: application/json' -H 'content-type: application/json' -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user", "content":"Hello, whats your name"}]}' -a wall_e https://chatapi.test.netflix.net:7004/chat/completion
