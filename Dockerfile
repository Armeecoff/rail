FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl unzip && \
    curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip xray.zip -d /usr/local/xray && \
    rm xray.zip && \
    apt-get remove -y unzip && apt-get autoremove -y

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

COPY start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
