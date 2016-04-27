# This is a build environment for creating Alpine packages.  This can be used
# in two ways: locally, or as an automated build.
#
# To work on packages locally, build and run this container using:
#
#     docker build -t aports .
#     docker run -it --rm -e VAULT_ADDR=https://vault-ha.faraday.io:8200/ -e VAULT_TOKEN=$(cat ~/.vault-token) -v $(pwd):/home/aports/aports aports sh
#     sudo apk update
#     cd testing/mypackage
#     abuild -r

FROM alpine:edge

# Change this if you need to change the signing key.
ENV PACKAGER_KEY=alpine@faraday.io-571f7fdf.rsa

# Do not add unnecessary development packages here; allow `abuild -r` to han
RUN apk -U add \
        alpine-sdk \
        sudo \
        && \
    rm -rf /var/cache/apk/* && \
    adduser -D aports && \
    addgroup aports aports && \
    addgroup aports wheel && \
    addgroup aports abuild && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel && \
    mkdir -p /home/aports/.abuild && \
    echo PACKAGER_PRIVKEY=\"/home/aports/.abuild/$PACKAGER_KEY\" > \
        /home/aports/.abuild/abuild.conf && \
    echo ">/home/aports/.abuild/$PACKAGER_KEY secret/aports/signing_key:private" \
        > /home/aports/Secretfile && \
    echo ">/home/aports/.abuild/$PACKAGER_KEY.pub secret/aports/signing_key:public" \
        >> /home/aports/Secretfile && \
    echo "AWS_ACCESS_KEY_ID aws/sts/aports:access_key" \
        >> /home/aports/Secretfile && \
    echo "AWS_SECRET_ACCESS_KEY aws/sts/aports:secret_key" \
        >> /home/aports/Secretfile && \
    echo "AWS_SESSION_TOKEN aws/sts/aports:security_token" \
        >> /home/aports/Secretfile && \
    VERS=v0.4.1 && \
    wget https://github.com/faradayio/credentials_to_env/releases/download/$VERS/credentials-to-env-$VERS-linux-x86_64.zip && \
    unzip credentials-to-env-$VERS-linux-x86_64.zip && \
    mv credentials-to-env /usr/local/bin && \
    rm credentials-to-env-$VERS-linux-x86_64.zip

ADD inputs/abuild.conf /etc/
ADD . /home/aports/aports
RUN chown -R aports:aports /home/aports

USER aports
WORKDIR /home/aports/aports

# Download our signing keys, etc., before we run a command in the
# container.
ENTRYPOINT ["credentials-to-env", "-f", "/home/aports/Secretfile"]

# Build our packages automatically if the user doesn't specify something
# else.
CMD ["/home/aports/aports/fdy-build"]
