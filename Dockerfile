FROM debian:bullseye-slim

# Dépendances système nécessaires
RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  openjdk-17-jdk \
  wget \
  gnupg \
  ca-certificates \
  npm \
  && apt-get clean

# Installer Flutter
ENV FLUTTER_VERSION=3.3.10
ENV DART_VERSION=2.19.2
ENV FLUTTER_HOME=/opt/flutter

RUN git clone https://github.com/flutter/flutter.git --branch $FLUTTER_VERSION --depth 1 $FLUTTER_HOME
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Activer Flutter
RUN flutter doctor -v

# Accepter les licences Android (optionnel si Android SDK est intégré par la suite)
RUN yes | flutter doctor --android-licenses || true

# Installer Firebase CLI
RUN npm install -g firebase-tools

# Créer un utilisateur non-root (optionnel)
RUN useradd -ms /bin/bash flutteruser
USER flutteruser
WORKDIR /home/flutteruser/app

CMD [ "bash" ]
