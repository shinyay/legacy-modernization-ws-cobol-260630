FROM ubuntu:22.04 AS ocesql-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        flex \
        bison \
        git \
        ca-certificates \
        pkg-config \
        gnucobol \
        libcob4-dev \
        libpq-dev \
        libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

ARG OCESQL_REPO=https://github.com/opensourcecobol/Open-COBOL-ESQL.git
ARG OCESQL_REF=develop

WORKDIR /tmp
RUN git clone --depth 1 --branch ${OCESQL_REF} ${OCESQL_REPO} ocesql

WORKDIR /tmp/ocesql
RUN autoreconf -fi \
 && ./configure --prefix=/usr/local \
 && make -j"$(nproc)" \
 && make install DESTDIR=/opt/ocesql-install \
 && find /opt/ocesql-install -type f | head -30

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Tokyo

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnucobol \
        libcob4-dev \
        build-essential \
        make \
        autoconf \
        gcc \
        pkg-config \
        libncurses-dev \
        libdb-dev \
        librabbitmq-dev \
        libpq-dev \
        libxml2 \
        postgresql-client \
        curl \
        jq \
        git \
        vim \
        less \
        ca-certificates \
        sudo \
        tzdata \
        locales \
        openjdk-17-jre-headless \
    && locale-gen en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo "Asia/Tokyo" > /etc/timezone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG FLYWAY_VERSION=10.22.0
RUN curl -fsSL "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz" \
        -o /tmp/flyway.tar.gz \
    && mkdir -p /opt/flyway \
    && tar -xzf /tmp/flyway.tar.gz --strip-components=1 -C /opt/flyway \
    && chmod -R a+rX /opt/flyway \
    && ln -sf /opt/flyway/flyway /usr/local/bin/flyway \
    && rm -f /tmp/flyway.tar.gz \
    && flyway --version

COPY --from=ocesql-builder /opt/ocesql-install/usr/local /usr/local
RUN ldconfig

RUN cat > /etc/profile.d/cobol.sh <<'EOF'
export COB_COPY_DIR="/workspace/shared/copy"
export COB_LIBRARY_PATH="/workspace/.build/lib:/usr/local/lib"
export COB_FILE_PATH="/workspace/data"
export COB_CFLAGS="-I/usr/local/include"
export COB_LDFLAGS="-L/usr/local/lib"
export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"

export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}"
export PGDATABASE="${PGDATABASE:-banking}"
export RABBITMQ_HOST="${RABBITMQ_HOST:-rabbitmq}"
export RABBITMQ_USER="${RABBITMQ_USER:-cobol}"
export RABBITMQ_PASS="${RABBITMQ_PASS:-cobol}"
EOF
RUN chmod 0644 /etc/profile.d/cobol.sh

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd  --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

RUN echo 'source /etc/profile.d/cobol.sh' >> /home/${USERNAME}/.bashrc \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

WORKDIR /workspace
USER ${USERNAME}

CMD ["sleep", "infinity"]
