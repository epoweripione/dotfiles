## [buildkitd.toml](https://docs.docker.com/build/buildkit/toml-configuration/)
- `/etc/buildkit/buildkitd.toml` for rootful mode
- `~/.config/buildkit/buildkitd.toml` for rootless mode
- A different path can be set with the `--config` flag or the `BUILDKITD_CONFIG` environment variable

## Fix: additional privileges requested: pass "--allow=network.host" to grant requested privileges

### [How to Use docker buildx Commands for Advanced Builds](https://oneuptime.com/blog/post/2026-02-08-how-to-use-docker-buildx-commands-for-advanced-builds/view)
```bash
cd /srv/web/simpleserver
docker buildx build --allow=network.host --load -t web-simpleserver:latest .
docker buildx history logs
```

### Build Docker images using `docker compose` with host network access
```bash
# [fix(bake): grant permissions for configured build inputs- #14325](https://github.com/docker/compose/pull/14325)
# a workaround is to put the `docker-compose` 5.7.0 binary in `~/.docker/cli-plugins`
[[ -z "${OS_INFO_TYPE}" ]] && get_os_type && get_arch

cd /tmp
curl -fSLO "https://github.com/docker/compose/releases/download/v5.7.0/docker-compose-${OS_INFO_TYPE}-${OS_INFO_CPU_ARCH}"
curl -fSLO "https://github.com/docker/compose/releases/download/v5.7.0/docker-compose-${OS_INFO_TYPE}-${OS_INFO_CPU_ARCH}.sha256"
shasum -a 256 -c "docker-compose-${OS_INFO_TYPE}-${OS_INFO_CPU_ARCH}.sha256"

mkdir -p ~/.docker/cli-plugins
rm -f ~/.docker/cli-plugins/docker-compose
cp "docker-compose-${OS_INFO_TYPE}-${OS_INFO_CPU_ARCH}" ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
docker compose version --short

# echo 'insecure-entitlements = [ "network.host", "security.insecure", "device" ]' | sudo tee /etc/buildkitd.toml >/dev/null

# docker buildx create --use --bootstrap \
#     --name="host-builder" \
#     --driver="docker-container" \
#     --buildkitd-config=/etc/buildkitd.toml

# docker exec -it buildx_buildkit_host-builder0 cat /etc/buildkit/buildkitd.toml

docker buildx create --use --bootstrap \
    --name="host-builder" \
    --driver="docker-container" \
    --driver-opt="network=host" \
    --buildkitd-flags="--allow-insecure-entitlement network.host"

docker compose build --builder host-builder

# Switch back to default builder
docker buildx ls
docker buildx use default
docker buildx rm host-builder
```
