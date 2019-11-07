#!/bin/sh

# 下記のようにしておけば
DUID=$(id -u) DGID=$(id -g) MYSQL_PW docker-compose $1 $2 $3 $4 $5 $6 $7 $8 $9
# 実行時に
#./docom.sh: 2: ./docom.sh: MYSQL_PW: not found
# とエラーが出て実行できない。
# 以下はテストのためにPWを入れておく
# DUID=$(id -u) DGID=$(id -g) MYSQL_PW=PWRoot1$ docker-compose $1 $2 $3 $4 $5 $6 $7 $8 $9
