FROM node:14-alpine

RUN npm install -g @mockoon/cli@0.1.0-beta.11
COPY mockoon-authorization-services.json ./data

# Build runner script
RUN echo "mockoon-cli start \"\$@\"; sleep infinity & wait \$!" > mockoon-runner.sh

# Do not run as root.
RUN adduser --shell /bin/sh --disabled-password --gecos "" mockoon
RUN chown -R mockoon ./mockoon-runner.sh
RUN chown -R mockoon ./data
USER mockoon

EXPOSE 3000

ENTRYPOINT sh mockoon-runner.sh -d data -c
# Usage: docker run -p <host_port>:<container_port> mockoon-test