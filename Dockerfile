FROM ubuntu:bionic
MAINTAINER Michal Čihař <michal@cihar.com>
ENV VERSION 3.2.2
LABEL version=$VERSION

# Add user early to get a consistent userid
RUN useradd --shell /bin/sh --user-group weblate \
  && mkdir -p /home/weblate/.ssh \
  && touch /home/weblate/.ssh/authorized_keys \
  && chown -R weblate:weblate /home/weblate \
  && chmod 700 /home/weblate/.ssh \
  && install -d -o weblate -g weblate -m 755 /app/data

# Configure utf-8 locales
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

COPY requirements.txt /usr/src/weblate/

# Install dependencies
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get -y upgrade \
  && apt-get install --no-install-recommends -y \
    sudo \
    uwsgi \
    uwsgi-plugin-python3 \
    netcat-openbsd \
    nginx \
    supervisor \
    openssh-client \
    curl \
    python3-pip \
    python3-lxml \
    python3-yaml \
    python3-pillow \
    python3-setuptools \
    python3-wheel \
    python3-psycopg2 \
    python3-dateutil \
    python3-rcssmin \
    python3-rjsmin \
    python3-hiredis \
    gettext \
    postgresql-client \
    mercurial \
    git \
    git-svn \
    subversion \
    python3-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libleptonica-dev \
    libtesseract-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    cython \
    gcc \
    g++ \
    tesseract-ocr \ 
    patch \
  && pip3 install Weblate==$VERSION -r /usr/src/weblate/requirements.txt \
  && ln -s /usr/local/share/weblate/examples/ /app/ \
  && rm -rf /root/.cache /tmp/* \
  && apt-get -y purge \
    python3-dev \
    libleptonica-dev \
    libtesseract-dev \
    libxml2-dev \
    libxmlsec1-dev \
    cython \
    gcc \
    g++ \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
  && apt-get -y autoremove \
  && apt-get clean \
  && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2

# Hub
RUN curl -L https://github.com/github/hub/releases/download/v2.2.9/hub-linux-amd64-2.2.9.tgz | tar xzv --wildcards hub-linux*/bin/hub && \
  cp hub-linux-amd64-2.2.9/bin/hub /usr/bin && \
  rm -rf hub-linux-amd64-2.2.9

# Settings
COPY settings.py /app/etc/
RUN chmod a+r /app/etc/settings.py && \
  ln -s /app/etc/settings.py /usr/local/lib/python3.6/dist-packages/weblate/settings.py

# Apply hotfixes
COPY patches /usr/src/weblate/
RUN cat /usr/src/weblate/*.patch | patch -p1 -d /usr/local/lib/python3.6/dist-packages/

# Configuration for nginx, uwsgi and supervisor
COPY weblate.nginx.conf /etc/nginx/sites-available/default
COPY weblate.uwsgi.ini /etc/uwsgi/apps-enabled/weblate.ini
COPY supervisor.conf /etc/supervisor/conf.d/

# Entrypoint
COPY start /app/bin/
RUN chmod a+rx /app/bin/start

ENV DJANGO_SETTINGS_MODULE weblate.settings

EXPOSE 80
ENTRYPOINT ["/app/bin/start"]
CMD ["runserver"]
