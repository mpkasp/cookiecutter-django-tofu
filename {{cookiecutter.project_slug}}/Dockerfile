ARG PYTHON_VERSION={{ cookiecutter.python_version }}
FROM python:${PYTHON_VERSION} AS base

ENV APP_HOME=/app
WORKDIR $APP_HOME

ARG SETTINGS_NAME

ENV SETTINGS_NAME=${SETTINGS_NAME}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN echo "settings name: $SETTINGS_NAME"

RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

ADD . ${APP_HOME}/
ENV PATH="${APP_HOME}/.venv/bin:$PATH"

RUN chmod +x startup.sh

CMD ["./startup.sh"]