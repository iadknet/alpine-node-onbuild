FROM mhart/alpine-node:4
Maintainer Isaac Stefanek <isaac@iadk.net>

ONBUILD ENV APP_USER node_app
ONBUILD ENV APP_ROOT /node_app

ONBUILD VOLUME /tmp

ONBUILD RUN npm install -g modclean && \
        mkdir -p ${APP_ROOT} && \
        mkdir /home/${APP_USER} && \
        addgroup -S ${APP_USER} && \
        adduser -S -g ${APP_USER} ${APP_USER}

ONBUILD ADD package.json /tmp/package.json
ONBUILD ADD npm-shrinkwrap.json /tmp/npm-shrinkwrap.json

ONBUILD RUN apk add --update git curl make gcc g++ python linux-headers paxctl libgcc libstdc++ && \
    cd /tmp && \
    npm install && \
    modclean -r && \
    mv /tmp/node_modules ${APP_ROOT}/node_modules && \
    apk del git curl make gcc g++ python linux-headers paxctl libgcc libstdc++ && \
    rm -rf /usr/include /etc/ssl /usr/share/man /var/cache/apk/* /root/.npm \
    /root/node-gyp /usr/lib/node_modules/npm/man usr/lib/node_modules/npm/doc \
    /usr/lib/node_modules/npm/html

ONBUILD ADD . ${APP_ROOT}

ONBUILD USER ${APP_USER}

ONBUILD WORKDIR ${APP_ROOT}

CMD ["node", "server.js"]
