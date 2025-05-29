FROM fischerscode/flutter:latest

# Install system dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg ca-certificates lsb-release && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g firebase-tools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

CMD [ "bash" ]
