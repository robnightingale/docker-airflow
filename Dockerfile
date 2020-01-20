FROM minidocks/python:3.7 as base

FROM base as builder

ENV AIRFLOW_COMPONENTS="crypto,celery,hive,jdbc,mysql,s3"

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ENV PACKAGES="\
  alpine-sdk \
  mariadb-dev \
  dumb-init \
  musl \
  linux-headers \
  build-base \
  ca-certificates \
  python3 \
  python3-dev \
  py-setuptools \
  openssh \
  libffi-dev \
  libxslt-dev \
  libxslt \
  libxml2 \
  libxml2-dev  \
  gcc \
"

RUN apk --update upgrade \
  && apk add --force $PACKAGES \
  && CFLAGS="-I/usr/include/libxml2"

RUN pip install -U pip apache-airflow["$AIRFLOW_COMPONENTS"] celery docker-py \
    paramiko \
    Cython \
    pytz \
    pyOpenSSL \
    ndg-httpsclient \
    pyasn1 \
    celery[redis]==4.1.1

FROM minidocks/python:3.7
#FROM alpine:3.9

#RUN apk add dumb-init python3
RUN apk add dumb-init
COPY --from=builder /opt/venv /opt/venv

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Airflow
ARG AIRFLOW_VERSION=1.10.7
ARG AIRFLOW_HOME=/airflow

ENV \
  AIRFLOW__CORE__AIRFLOW_HOME=$AIRFLOW_HOME \
  AIRFLOW__CORE__DAGS_FOLDER=$AIRFLOW_HOME/dags \
  AIRFLOW__CORE__BASE_LOG_FOLDER=$AIRFLOW_HOME/logs \
  AIRFLOW__CORE__PLUGINS_FOLDER=$AIRFLOW_HOME/plugins \
  AIRFLOW__CORE__EXECUTOR=SequentialExecutor \
  AIRFLOW__CORE__SQL_ALCHEMY_CONN=sqlite://$AIRFLOW_HOME/airflow.db \
  AIRFLOW__CORE__LOAD_EXAMPLES=False

COPY dags/ $AIRFLOW_HOME/dags
COPY script/entrypoint.sh /

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN cd /home && mkdir airflow && cd airflow \
  && adduser -S airflow \
  && chown -R airflow: ${AIRFLOW_HOME}
USER airflow

EXPOSE 8080 5555 8793

CMD ["airflow", "webserver"]
ENTRYPOINT ["/entrypoint.sh"]
