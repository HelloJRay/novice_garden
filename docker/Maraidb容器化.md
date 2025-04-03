docker run -d  --name cost_server_mariadb  --restart=unless-stopped  -p 13306:3306  -e MYSQL_ROOT_PASSWORD=rayroot \
           -v /home/ray/home_ray_app/home_ray_app/com-ray-cost/docker-app/app_data_volumes/db_data_cost_server_mariadb:/var/lib/mysql \
           -v /home/ray/home_ray_app/home_ray_app/com-ray-cost/docker-app/app_data_volumes/init_sql_cost_server:/docker-entrypoint-initdb.d \
           ray-amd64-mariadb:10.11
