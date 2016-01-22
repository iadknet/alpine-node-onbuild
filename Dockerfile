FROM mhart/alpine-node:4
Maintainer Isaac Stefanek <isaac@iadk.net>

# Run your node app as a non-root user
ONBUILD ENV APP_USER node_app
ONBUILD ENV APP_ROOT /node_app

# List of packages that need to be installed for node_modules to compile
ONBUILD ENV APK_PACKAGES git curl make gcc g++ python linux-headers paxctl libgcc libstdc++

# Packages to be removed after npm install and not take up any space
# in the final image.
ONBUILD ENV DEL_PACKAGES git curl make gcc g++ python linux-headers paxctl

# Mount the /tmp directory on the host during build
# so initial node_modules build does not take up space
# in final image
ONBUILD VOLUME /tmp

# Install modclean package and set up user
# Node modules can be very large.
# modclean slims them down by removing extraneous files
ONBUILD RUN npm install -g modclean && \
        mkdir -p ${APP_ROOT} && \
        mkdir /home/${APP_USER} && \
        addgroup -S ${APP_USER} && \
        adduser -S -g ${APP_USER} ${APP_USER}

# Add package.json and shrinkwrap.json
# Shrinkwrap is important to make sure
# package versions stay consistent between builds
ONBUILD ADD package.json /tmp/package.json
ONBUILD ADD npm-shrinkwrap.json /tmp/npm-shrinkwrap.json

# Install apk packages and node modules
# This step should only run in package.json or npm-shrinkwrap.json
# files have changed. Otherwise this layer should be cached.
ONBUILD RUN apk add --update ${APK_PACKAGES} && \
    cd /tmp && \
    npm install && \
    modclean -r && \
    mv /tmp/node_modules ${APP_ROOT}/node_modules && \
    apk del ${DEL_PACKAGES} && \
    rm -rf /usr/include /etc/ssl /usr/share/man /var/cache/apk/* /root/.npm \
    /root/node-gyp /usr/lib/node_modules/npm/man usr/lib/node_modules/npm/doc \
    /usr/lib/node_modules/npm/html

# Add the code for our app
ONBUILD ADD . ${APP_ROOT}

# Run our app as a non-root user
ONBUILD USER ${APP_USER}

ONBUILD WORKDIR ${APP_ROOT}

CMD ["node", "server.js"]
