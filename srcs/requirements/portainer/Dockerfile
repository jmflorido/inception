FROM alpine:3.23

RUN apk add --no-cache tar ca-certificates

RUN mkdir -p /data /portainer /var/run

RUN wget https://github.com/portainer/portainer/releases/download/2.45.3/portainer-2.45.3-linux-amd64.tar.gz -O /portainer/portainer.tar.gz

RUN tar -xvzf /portainer/portainer.tar.gz

#COPY /var/run/docker.sock /var/run/docker.sock

EXPOSE 9443
EXPOSE 8000

WORKDIR /portainer

CMD ["./portainer", "--no-setup-token", "--data", "/data"] 
