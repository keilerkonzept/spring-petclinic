#!/usr/bin/env bash
set -e

case $(uname -m) in
    arm64)   url="https://cdn.azul.com/zulu/bin/zulu17.44.17-ca-crac-jdk17.0.8-linux_aarch64.tar.gz" ;;
    *)       url="https://cdn.azul.com/zulu/bin/zulu17.44.17-ca-crac-jdk17.0.8-linux_x64.tar.gz" ;;
esac

echo "Using CRaC enabled JACK $url"

readonly org=keilerkonzept
readonly repo=petclinic-on-crac

# mkdir -p "$(pwd)"/crac-files
rm -f target/checkpoint_complete > /dev/null

./mvnw package -DskipTests
docker build -t $org/$repo:builder --build-arg CRAC_JDK_URL=$url .
docker run --privileged --rm --name=$repo --ulimit nofile=1024 -p 8080:8080 -v $(pwd)/target:/opt/mnt $org/$repo:builder &

# busy wait until the checkpoint has been written, then commit the running container
while :
do
	if [ -f "target/checkpoint_complete" ]; then
    echo "committing container..."
    docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=$repo") $org/$repo:checkpoint
    docker kill $(docker ps -qf "name=$repo")
    echo "container committed"
    exit
  fi
done
