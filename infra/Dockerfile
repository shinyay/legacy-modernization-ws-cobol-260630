# infra/Dockerfile — Practice Bank 共有ランタイム image（rehost / ADR-0026,0027）
# COBOL(GnuCOBOL)+OCESQL を1枚に同梱。ジョブ/サブシステム単位の起動は command で切替。
# 出典: legacy/.../.devcontainer/Dockerfile のツールチェーンを本番向けに整理。

# ── stage1: OCESQL ビルド ─────────────────────────────────────────────
FROM ubuntu:22.04 AS ocesql-builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential autoconf automake libtool flex bison git ca-certificates \
        pkg-config gnucobol libcob4-dev libpq-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*
ARG OCESQL_REPO=https://github.com/opensourcecobol/Open-COBOL-ESQL.git
ARG OCESQL_REF=develop
WORKDIR /tmp
RUN git clone --depth 1 --branch ${OCESQL_REF} ${OCESQL_REPO} ocesql
WORKDIR /tmp/ocesql
RUN autoreconf -fi && ./configure --prefix=/usr/local && make -j"$(nproc)" \
 && make install DESTDIR=/opt/ocesql-install

# ── stage2: 本番ランタイム ────────────────────────────────────────────
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TZ=Asia/Tokyo \
    COB_COPY_DIR=/workspace/shared/copy COB_FILE_PATH=/workspace/data
RUN apt-get update && apt-get install -y --no-install-recommends \
        gnucobol libcob4-dev make gcc pkg-config libncurses-dev libdb-dev \
        librabbitmq-dev libpq-dev libxml2 postgresql-client curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=ocesql-builder /opt/ocesql-install/usr/local/ /usr/local/
RUN ldconfig
WORKDIR /workspace
COPY . /workspace
# ビルドは CI/コンテナで実施（ADR-0013）。例: make build-all
# 起動はジョブ単位。日次/月次/取引パイプを command で切替（ACA Jobs）。
#   ACA Job 例: ["bash","subsystems/22-operations/bin/run-batch-daily-wrapper.sh","daily"]
ENTRYPOINT ["/bin/bash","-lc"]
CMD ["echo 'practice-bank runtime: specify a job command (e.g. make build-all)'"]
