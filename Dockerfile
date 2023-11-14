FROM almalinux:9.1

ENV ISO_URL="https://repo.almalinux.org/vault/9.1/isos/x86_64" \
    ISO_NAME="AlmaLinux-9.1-x86_64-boot.iso"

WORKDIR /workdir

COPY *.sh templ_* ks.cfg packages*.txt ./

RUN dnf -y swap curl-minimal curl && \
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
    curl -L -o ${ISO_NAME} ${ISO_URL}/${ISO_NAME} && \
    chmod +x *.sh

#    ./create_iso_in_container.sh

CMD ["/bin/bash"]
