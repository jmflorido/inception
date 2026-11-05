FROM alpine:3.23

RUN apk add --no-cache wget tar ca-certificates

RUN mkdir -p /data /portainer

RUN wget https://github.com/portainer/portainer/releases/download/2.45.3/portainer-2.45.3-linux-amd64.tar.gz -O /portainer/portainer.tar.gz

#RUN wget https://github.com/portainer/portainer/releases/download/2.45.3/portainer-2.45.3-linux-arm64.tar.gz -O /portainer/portainer.tar.gz
RUN tar -xvzf /portainer/portainer.tar.gz

EXPOSE 9443
EXPOSE 8000

WORKDIR /portainer

#CMD ["./portainer", "--trusted-origins", "https://portainer.joflorid.42.fr", "--no-setup-token", "--data", "/data"] 
CMD ["./portainer", "--data", "/data"] 
