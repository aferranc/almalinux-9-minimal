FROM almalinux:9.1

ENV ISO_URL="https://repo.almalinux.org/vault/9.1/isos/x86_64" \
    ISO_NAME="AlmaLinux-9.1-x86_64-boot.iso"

WORKDIR /workdir

RUN echo "sslverify=false" >> /etc/yum.conf && \
    dnf -y swap curl-minimal curl && \
    dnf install -y  yum-utils \
                    createrepo \
                    syslinux \
                    genisoimage \
                    isomd5sum \
                    bzip2 \
                    file \
                    git \
                    wget \
                    unzip && \
    curl -k -L -o ${ISO_NAME} ${ISO_URL}/${ISO_NAME}

CMD ["/bin/bash"]
