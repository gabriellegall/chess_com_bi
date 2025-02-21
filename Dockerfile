FROM python:3.9-slim

ENV DBT_HOME=/chess_com_bi
WORKDIR $DBT_HOME

RUN apt-get update && \
    apt-get install -y \
        git && \
    rm -rf /var/lib/apt/lists/*

COPY . .
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install -r requirements.txt

CMD ["/bin/bash"]
# CMD ["dbt", "seed", "--select", "customer", "--target", "prod"]