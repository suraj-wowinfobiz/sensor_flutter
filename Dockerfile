FROM ghcr.io/cirruslabs/flutter:3.32.5 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG ADMIN_API_BASE_URL=http://103.211.202.145:8091
ARG USER_API_BASE_URL=http://103.211.202.145:8091
ARG USER_ADMIN_API_BASE_URL=http://103.211.202.145:8091
ARG ENGINEER_API_BASE_URL=http://195.250.21.120:8091
ARG VENDOR_API_BASE_URL=http://195.250.21.120:8091

RUN flutter build web --release \
    --dart-define=ADMIN_API_BASE_URL=${ADMIN_API_BASE_URL} \
    --dart-define=USER_API_BASE_URL=${USER_API_BASE_URL} \
    --dart-define=USER_ADMIN_API_BASE_URL=${USER_ADMIN_API_BASE_URL} \
    --dart-define=ENGINEER_API_BASE_URL=${ENGINEER_API_BASE_URL} \
    --dart-define=VENDOR_API_BASE_URL=${VENDOR_API_BASE_URL}

FROM nginx:1.27-alpine

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
