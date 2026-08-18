#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ "$1" == "clean" ]; then
    docker compose down
    exit 0
elif [ "$1" == "run" ]; then
    docker compose up -d --build

    DB_READY=false
    for i in {1..5}; do
        if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
            DB_READY=true
            break
        fi
        sleep 2
    done

    if [ "$DB_READY" == false ]; then
        echo -e "${RED}[LỖI] Database không phản hồi sau 10 giây!${NC}"
        docker compose down
        exit 1
    fi

    sleep 5

    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/users/actuator/health)

    if [ "$STATUS" == "200" ]; then
        echo -e "${GREEN}CỔNG GATEWAY HOẠT ĐỘNG ỔN ĐỊNH. HỆ THỐNG LIÊN THÔNG THÀNH CÔNG!${NC}"
        exit 0
    else
        echo -e "${RED}[LỖI] Gateway trả về mã lỗi HTTP: $STATUS${NC}"
        docker compose logs --tail=30
        docker compose down
        exit 1
    fi
else
    exit 1
fi