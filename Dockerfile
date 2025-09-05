# syntax=docker/dockerfile:1

ARG C="kratos-selfservice-ui-node"
ARG W="/workspace"
ARG A="${W}/subsystem/app"

FROM node:18-alpine AS release
ARG C
ARG A
ARG W
ARG LINK=no
WORKDIR /usr/src/app
LABEL org.opencontainers.image.source=https://github.com/szn-app/wosoom

RUN adduser -S ory -D -u 10000 -s /bin/nologin
RUN mkdir -p /usr/src/app

COPY package.json package-lock.json ./
COPY . .
# COPY --from=crate . ${W}/crate/

RUN npm ci --fetch-timeout=600000

RUN if [ "$LINK" == "true" ]; then \
    (pushd ./contrib/sdk/generated; \
    rm -rf node_modules; \
    npm ci; \
    npm run build; \
    popd); \
    cp -r ./contrib/sdk/generated/* node_modules/@ory/kratos-client/; \
    fi

RUN npm run build

USER 10000
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["npm run serve"]
EXPOSE 3000

FROM node:lts AS debug
ARG C
ARG A
ARG W
WORKDIR /usr/src/app

RUN mkdir -p /usr/src/app

COPY . /usr/src/app
COPY --from=crate . ${W}/crate/
RUN npm install

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["npm run dev"]
