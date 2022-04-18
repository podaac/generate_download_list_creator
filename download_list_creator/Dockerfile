# Stage 0 - Create from Python 3.10-alpine3.15 image
# FROM python:3.10-alpine3.15 as stage0
FROM python:3.10-alpine3.15
RUN apk add --no-cache --upgrade tcsh

# Stage 1 - Install dependencies
# FROM stage0 as stage1
COPY requirements.txt /app/requirements.txt
RUN /usr/local/bin/python3 -m venv /app/env
RUN /app/env/bin/pip install -r /app/requirements.txt

# Stage 2 - Copy Generate code
# FROM stage1 as stage2
RUN /bin/mkdir /data
COPY . /app

# Stage 3 - Execute code
# FROM stage2 as stage3
LABEL version="0.1" \
    description="Containerized Generate: Download List Creator"
ENTRYPOINT [ "/bin/tcsh", "/app/shell/startup_generic_download_list_creator.csh" ]