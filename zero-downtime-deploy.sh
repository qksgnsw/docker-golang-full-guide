#!/bin/sh

reload_nginx() {
  docker exec nginx /usr/sbin/nginx -s reload
}

service_name=web
replicas=3

old_container_id=$(docker ps -f name=$service_name -q | tail -n$replicas)
if [ -z $old_container_id ]; then
  echo "info : $1 서비스가 없습니다."
  exit 1
fi

image_name=$(docker ps -f name=$service_name --format "{{.Image}}")
docker pull $image_name

docker-compose up -d --no-deps --scale $service_name=$(($replicas*2)) --no-recreate $service_name

# wait for new container to be available
# new_container_id=$(docker ps -f name=$service_name -q | head -n1)
# new_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $new_container_id)
# curl --silent --include --retry-connrefused --retry 30 --retry-delay 1 --fail http://$new_container_ip:3000/ || exit 1

reload_nginx

docker stop $old_container_id
docker rm $old_container_id

docker-compose up -d --no-deps --scale $service_name=$replicas --no-recreate $service_name

reload_nginx

echo y | docker container prune && echo y | docker image prune
