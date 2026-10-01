FROM alpine:3.21

# Alpine's ffmpeg is built with libx264 and libx265.
RUN apk add --no-cache bash ffmpeg

COPY --chmod=0755 bin/ /usr/local/bin/

USER 1000:1000
WORKDIR /tmp

CMD ["compress-videos"]
