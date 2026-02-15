FROM apache/airflow:3.1.6-python3.12

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER airflow
ENTRYPOINT ["/entrypoint.sh"]
