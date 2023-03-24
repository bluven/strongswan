FROM alpine:3.15 as builder

ENV STRONGSWAN_RELEASE https://download.strongswan.org/old/5.x/strongswan-5.9.8.tar.bz2

RUN apk --update add build-base \
            curl \
            clang \
            ca-certificates \
            gmp-dev \
            iptables-dev \
            openssl-dev && \
    mkdir -p /tmp/strongswan && \
    curl -Lo /tmp/strongswan.tar.bz2 $STRONGSWAN_RELEASE && \
    tar --strip-components=1 -C /tmp/strongswan -xjf /tmp/strongswan.tar.bz2 && \
    cd /tmp/strongswan && \
    ./configure CC=clang \
            --prefix=/usr \
            --sysconfdir=/etc \
            --libexecdir=/usr/lib \
            --with-ipsecdir=/usr/lib/strongswan \
            --enable-aesni \
            --enable-cmd \
            --enable-eap-identity \
            --enable-eap-md5 \
            --enable-eap-mschapv2 \
            --enable-eap-radius \
            --enable-eap-tls \
            --enable-openssl \
            --enable-shared \
            --enable-gmp \
            --enable-eap-aka \
            --enable-eap-aka-3gpp2 \
            --enable-eap-sim \
            --enable-eap-simaka-pseudonym \
            --enable-eap-simaka-reauth \
            --enable-unity \
            --enable-xauth-eap \
            --enable-xauth-generic \
            --enable-mediation \
            --disable-aes \
            --disable-des \
            --disable-hmac \
            --disable-ikev1 \
            --disable-md5 \
            --disable-rc2 \
            --disable-sha1 \
            --disable-sha2 \
            --disable-kdf \
            --disable-gcm \
            --disable-static && \
    make && \
    make install 


FROM alpine:3.15

RUN --mount=type=bind,from=builder,source=/,target=/builder cp -r /builder/etc/strongswan.d/ \
        /builder/etc/strongswan.conf \
        /builder/etc/ipsec.d/ \
        /builder/etc/ipsec.conf \
        /builder/etc/swanctl \
        /etc/ && \
        cp -r /builder/usr/sbin/charon-cmd \
        /builder/usr/sbin/swanctl \ 
        /builder/usr/sbin/ipsec \
        /usr/sbin/ && \
        cp -r /builder/usr/share/strongswan /usr/share/ && \
        cp -r /builder/usr/lib/strongswan /builder/usr/lib/ipsec /usr/lib && \
        cp /builder/usr/bin/pki /usr/bin && \
        sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
        apk --update add gmp-dev && \
        sed -i 's/# install_routes = yes/install_routes = no/' /etc/strongswan.d/charon.conf && \
        rm -rf /var/cache/apk/

EXPOSE 500/udp 4500/udp

ENTRYPOINT ["/usr/sbin/ipsec"]

CMD ["start", "--nofork"]
