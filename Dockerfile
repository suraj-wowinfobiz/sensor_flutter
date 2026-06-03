FROM ghcr.io/cirruslabs/flutter:3.32.5 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Verify assets exist
RUN ls -la assets/ || echo "No assets directory"
RUN ls -la assets/images/ || echo "No images directory"

RUN flutter clean
RUN flutter pub get

# Verify assets are in place before build
RUN test -f assets/images/construction.jpg && echo "Image found" || echo "Image missing"

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

# Verify image is in build output
RUN ls -la /app/build/web/assets/assets/images/ || echo "Images not in build"

FROM nginx:1.27-alpine

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
