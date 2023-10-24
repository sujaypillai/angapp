# syntax=docker/dockerfile:1

# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS build
ARG TARGETARCH
WORKDIR /source

# optimize 
COPY PPUI.Web.csproj /source
RUN dotnet restore

# Build the application.
# Leverage a cache mount to /root/.nuget/packages so that subsequent builds don't have to re-download packages.
# If TARGETARCH is "amd64", replace it with "x64" - "x64" is .NET's canonical name for this and "amd64" doesn't
#   work in .NET 6.0.
#RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
#    dotnet publish -a ${TARGETARCH/amd64/x64} --use-current-runtime --self-contained false -o /app
COPY . /source
# install node for angular build
# COPY --from=node:21-alpine3.17 /usr/local/bin/yarn /usr/local/bin/yarn
# COPY --from=node:21-alpine3.17 /usr/local/bin/node /usr/local/bin/node
# COPY --from=node:21-alpine3.17 /usr/local/bin/npm /usr/local/bin/npm

RUN apk add --update nodejs npm

RUN dotnet build -c Release -o /app
RUN dotnet publish -c Release -o /app /p:UseAppHost=false
# If you need to enable globalization and time zones:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/enable-globalization.md
################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
#
# The example below uses an aspnet alpine image as the foundation for running the app.
# It will also use whatever happens to be the most recent version of that tag when you
# build your Dockerfile. If reproducability is important, consider using a more specific
# version (e.g., aspnet:7.0.10-alpine-3.18),
# or SHA (e.g., mcr.microsoft.com/dotnet/aspnet@sha256:f3d99f54d504a21d38e4cc2f13ff47d67235efeeb85c109d3d1ff1808b38d034).
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine AS final
WORKDIR /app

# Copy everything needed to run the app from the "build" stage.
COPY --from=build /app .

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser
# USER appuser
EXPOSE 8080 8443

CMD ["dotnet", "PPUI.Web.dll"]
