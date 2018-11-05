FROM scratch
MAINTAINER wuliying
EXPOSE 8080
ENTRYPOINT ["/golang-http"]
COPY ./bin/ /
