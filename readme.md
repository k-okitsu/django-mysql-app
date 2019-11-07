# Alpine3 + Python3 + Django2 + uwgsi + nginx + mysql8 による Docker 環境構築

## 概要

最初に、こちらは勉強用として作成しており本番環境等で使えるようにはなっていません。<br />
その辺りご配慮いただければ幸いです。<br />
<br />
では Django 開発環境を構築します。<br />
Django はテスト用に簡易サーバーを持っていますが、本番にも使える nginx を使って構築したいと思います。<br />
DataBase には MySQL8.0 を使います。<br />
<br />
また、docker内で現在のユーザーを追加するため linux の id コマンドを使っています。<br />
そのため下記動作確認済み環境以外では動かない可能性があります。<br />
docker はできるだけ最新バージョンを使い、もしも動かなかった場合はご容赦下さい。<br />
<br />
それと同封の docom.sh は docker-compose を起動する際にユーザーID等をセットするためのシェルスクリプトです。<br />
```
$ cat docom.sh
DUID=$(id -u) DGID=$(id -g) MYSQL_PW=hogehoge docker-compose $1 $2 $3 $4 $5 $6 $7 $8 $9 
```
DUID と DGID にユーザーIDとグループIDを入れ、MySQLのルートユーザーのパスワードをMYSQL_PWに入れてから docker-compose を呼び出すだけのものです。（こういう場合はエイリアスを使うほうが良いのだろうか？）<br />
clone すると下記のようになっています。<br />
```
DUID=$(id -u) DGID=$(id -g) MYSQL_PW docker-compose $1 $2 $3 $4 $5 $6 $7 $8 $9 
```
**必ず docom.sh を編集して MYSQL_PW=mysql_root_password のようにパスワード文字列を入れて下さい。**<br />
**あくまで開発及びテスト用として使っており、セキュリティに注意すべき環境では別の方法でお願いします。**<br />

### 動作確認済みの環境<br/>

- Ubuntu 18.04.3 LTS<br />
  Docker version 19.03.4, build 9013bf583a<br />
  docker-compose version 1.24.0, build 0aa59064<br />

- Windows 10 Enterprise 1903 build 18362.418<br />
  Docker for Windows を使用<br />
  Docker version 19.03.4, build 9013bf5<br />
  docker-compose version 1.24.1, build 4667896b<br />
  **【注意】コマンドの実行は必ず Git-Bash 上で行って下さい。**<br />
  **PowerShell では id コマンドが使えないため動きません。**<br />

### 各種インストールバージョン

- Alpine 3.1.0<br />
- Python 3.7.4<br />
- Django 2.2.7 or later<br />
- uwsgi  2.0.18 or later<br />
- mysqlclient 1.4.4 or later<br />

&emsp;&emsp; Python と Alpine は Python の公式リポジトリにあれば Dockerfile を編集して別のバージョンを使う事が出来ます。<br />

### フォルダ構成<br/>
- フォルダ及びファイルの構成
  ```
  + db
    + conf
      - mysql_my.cnf
    + data
      - __init__.txt
    + sqls
      - __init__.txt
  + nginx
    - uwsgi_params
    + conf
      - nginx_my.conf
  + web
    - Dockerfile
    - requirements.txt
    - uwsgi.ini
  - docker-compose.yml
  - .gitignore
  - readme.md
  - docom.sh
  + log
    + uwsgi
      - __init__.txt
  + static
    - __init__.txt
  + media
    - __init__.txt
  + src
    - __init__.txt
  ```
  log, static, media, src はマウントするために必要で実際には空フォルダです。<br />
  （gitで空フォルダを保持するためだけに \_\_init\_\_.txt を入れています）

## 手順

1. git clone します<br />
  **注意**<br />
  clone 出来たらまず `db/__init__.txt` ファイルを削除して下さい。<br />
  これがあると MySQL の初期化で失敗しエラーが出ます。
  次に、docom.sh を編集して MYSQL_PW=mysql_root_password のようにパスワード文字列を入れて下さい。<br />

2. docker image を作成するためビルドします<br />
  下記コマンドを docker-compose.yml ファイルのあるフォルダで実行して docker Image を作成します<br />
  `$ ./docom.sh build web` <br />
  もしくは<br />
  `$ DUID=$(id -u) DGID=$(id -g) MYSQL_PW=mysql_root_password docker-compose build web` <br />

3. Django project を作成します<br />
    - django-admin startproject で新規作成する場合<br />
      **初めに!!**<br />
      DB の　テーブル名を決めて下さい。
      `db/conf/mysql_my.cnf` ファイルの27行目辺りに <br />
      ```
      - MYSQL_DATABASE=mysite
      ```
      という部分があります。この mysite をこれから作成するプロジェクト名や適当な名前に変更して下さい。<br />
      DBの名前を変更したら、下記コマンドを実行してプロジェクトを作成します。<br />
      &emsp; `$ ./docom.sh run web django-admin startproject <project name>` <br />
      &emsp; もしくは<br />
      &emsp; `$ DUID=$(id -u) DGID=$(id -g) MYSQL_PW=mysql_root_password docker-compose run web django-admin startproject <project name>` <br />
      &emsp; docker環境下で /code/ フォルダ、ローカル環境では ./src/ フォルダにプロジェクトが作成されます。<br />
      &emsp; **MySQLサーバーの立ち上げで失敗する場合は `db/data/` のファイルを全て削除してやり直して下さい**<br />
      &emsp; テストプロジェクトは mysite という名前で作っているため、mysite で作ると以降のプロジェクト名の修正は不要です。<br />
      &emsp; もしうまく行かない場合はproject name を 「mysite」 で作り手順 3. の uwsgi.ini を src/mysite/mysite へコピーし手順 8. を行えばサーバーが起動するはずです。<br />
      <br />
    - 既存のDjangoアプリを使う場合  
      ローカル環境の ./src/ フォルダ以下に \<project name\>/\<project name\>/manage.py がある構成でコピーします  
      例）mysite project で myapp アプリが作られている場合は以下のような構成が想定されます
      ```
      + src
        - manage.py
        + mysite
          + mysite
            - __init__.py
            - urls.py
            - wsgi.py
            - settings.py
          + myapp
            - apps.py
            - models.py
            - views.py
      ```
4. ./web/uwsgi.ini ファイルを `./src/<project name>/<project name>/` へコピーします  
  **(ここは新規プロジェクトを作成した場合のみ)**<br />
  これはローカル環境で行います<br />
  docker環境下では `/code/<project name>/<project name>/uwsgi.ini` に配置する事になります。

5. 手順4. でコピーした `./src/<project name>/<project name>/uwsgi.ini` ファイルを修正します  
  **(ここは新規プロジェクトを作成した場合のみ)**<br />
  prjname=mysite となっている部分を 2. で作成もしくはコピーしたプロジェクト名に変更します。<br />
  その他に変更すべき箇所があればそこも適宜おこないます。<br />

6. docker-compose.yml を修正します<br />
  uwsgi のパラメータにある /mysite/ 部分を 2. で作成もしくはコピーしたプロジェクト名に変更します。<br />
    ```
    修正前  command: uwsgi --ini /code/mysite/mysite/uwsgi.ini
    修正後  command: uwsgi --ini /code/<project name>/<project name>/uwsgi.ini
    ```
7. `./nginx/conf/nginx_my.conf` を修正します（必要があれば）<br />
  localhost 以外のサーバーで動かす場合はこのファイルの server_name の設定を変更します<br />
  また、nginx の設定が変更な場合はここで行えます<br />
  ファイル名は適当に変更する事も別途このフォルダに設定ファイル(*.conf)を追加する事も出来ます<br />
  （この ./nginx/conf/ フォルダを /etc/nginx/conf.d にマウントさせているため）<br />

8. サーバーを起動します  
    ```
    $ ./docom.sh up -d
    もしくは
    $ DUID=$(id -u) DGID=$(id -g) MYSQL_PW=mysql_root_password docker-compose up -d
    ```
    webブラウザで、http://localhost:8080 にアクセスすると Django アプリが起動します<br />
    django-admin startproject でプロジェクトを作っただけなら Django のデモ画面が表示されるはずです。  

9. `$ ./docom.sh down` でサーバーを終了します  

10. ログファイルはローカル環境の ./log/ 以下に集約して保存されます  
  ./log/nginx/ : nginx のログ<br />
  ./log/uwsgi/ : uwsgi のログ<br />

11. アプリケーションを作ります
  **(ここは新規プロジェクトを作成した場合、もしくはアプリを追加する場合)**<br />
  ここで作るアプリケーション名は仮に `myapp` としておきます。作りたいアプリ名に置き換えて読んで下さい。<br />
  また以下２つの方法があります。どちらでも好きな方法で作る事が出来ます。<br />

    **・方法１：docker-compose run web で作る場合**<br />
      &emsp; アプリケーションの作成は manage.py のあるフォルダで行うためワークフォルダを指定する必要があります。<br />
      &emsp; `docker-compose run -w //code/mysite/` で指定できるので、これを使います。<br />
      &emsp; (ubuntu では /code/mysite/ でも動いたのですが、Windows10 では //code/mysite/ でなければ動きませんでした。)<br />
      &emsp; (mysite には手順 3. で作ったプロジェクト名を入れて下さい) <br />
      ```
      $ ./docom.sh run -w //code/mysite/ web python manage.py startapp myapp
      ```

    **・方法２：サーバーを起動させて docker exec によりコンテナ内に入って作業をする場合**<br />
      &emsp; ubuntu の場合
      ```
      $ ./docom.sh up -d
      $ docker exec -it django.web /bin/sh
      /code $ とプロンプトが出ればコンテナ内に入れています。
      $ cd mysite
      $ python manage.py startapp myapp
      $ exit
      ```
      &emsp; Windows10 の場合
      ```
      $ ./docom.sh up -d
      $ winpty docker exec -it django.web sh
      /code $ とプロンプトが出ればコンテナ内に入れています。
      $ cd mysite
      $ python manage.py startapp myapp
      $ exit
      ```
      &emsp; (mysite には手順 3. で作ったプロジェクト名を入れて下さい) <br />

    これでアプリケーションが作成されました。<br />

12. アプリケーションへアクセスできるように様にビューとurlsを指定します。<br />
    ここからは Django のチュートリアル Polls と同様の作業となります。<br />
    そのため、入り口となるビューとurlsを作成するまでを説明します。<br />
    これらはローカルで作業する事も、コンテナ内で作業する事も出来ます。<br />
    今回はローカル環境で作業します。<br />

    1. src/mysite/myapp/views.py を下記のように編集します。<br />

        ```Python
        from django.http import HttpResponse

        def index(request):
            return HttpResponse("Hello, world. You're at the myapp index.")   
        ```
    <br />

    2. src/mysite/myapp/ フォルダに urls.py ファイルを作成し、下記コードを書きます。<br />

        ```Python
        from django.urls import path

        from . import views

        urlpatterns = [
            path('', views.index, name='index'),
        ]
        ```
    <br />
    
    3. 次に src/misite/urls.py ファイルを下記のように書き換えます。<br />

        ```Python
        from django.contrib import admin
        from django.urls import include, path

        urlpatterns = [
            path('myapp/', include('myapp.urls')),
            path('admin/', admin.site.urls),
        ]
        ```
  13. アプリの動作確認をします<br />
    ./docom.sh up -d でサーバーを起動し、http://localhost:8080/myapp へアクセスします。<br />
    URL には /myapp を付けて下さい。locaphost:8080 だけだと Page not found(404)エラーが出ます。<br />
    ブラウザ画面に「Hello, world. You're at the myapp index.」と表示されれば成功です。<br />

  14. collectstatic でスタティックファイルを所定のフォルダへ集めます。<br />
      はじめに mysite/mysite/settings.py の最後に STATIC_ROOT の設定を追記します。<br />
      これを入れないと collectstatic で下記のエラーが出ます。<br />

      ```
      django.core.exceptions.ImproperlyConfigured: You're using the staticfiles app without having set the STATIC_ROOT setting to a filesystem path.
      ```
      ついでに、日本語、と日本時間の設定も変更しておきましょう。<br />
      LANGUAGE_CODE を 'ja' に、TIME_ZONE を 'Asia/Tokyo' に変更します。（下記のように）<br />

      **/code/mysite/mysite/settings.py**
      ```python
      |
      〜いろいろ〜
      |
      LANGUAGE_CODE = 'ja'

      TIME_ZONE = 'Asia/Tokyo'
      |
      〜いろいろ〜
      |
      STATIC_URL = '/static/'
      STATIC_ROOT = STATIC_URL      # これを追加
      ```

      collectstatic を行います。  

      ```
      $ ./docom.sh run -w /code/mysite/ web python manage.py collectstatic
      ```
      もしくは、
      ```
      $ ./docom.sh up -d
      $ docker exec -it django.web /bin/sh
      /code $ とプロンプトが出ればコンテナ内に入れています。
      $ cd mysite
      $ python manage.py collectstatic
      $ exit
      ```
      （Windows10 の場合は `winpty docker exec -it django.web sh` でコンテナに入ります。）<br />
      エラーが出なければ ./static フォルダに admin フォルダが追加されているはずです。<br />

  15. 次に管理画面を使えるように MySQL DB に migrate で必要なテーブル等を書き込みます<br />
    今回も２つの方法があります。好きな方で作って下さい。<br />
    **・方法１：docker-compose run web で migrate する場合**<br />
      `$ ./docom.sh run -w //code/mysite/ web python manage.py migrate`<br />
      <br />
    **・方法２：サーバーを起動させて docker exec によりコンテナ内に入って migrate する場合**<br />
      ```
      $ ./docom.sh up -d
      $ docker exec -it django.web /bin/sh
      /code $ とプロンプトが出ればコンテナ内に入れています。
      $ cd mysite
      $ python manage.py migrate
      $ exit
      ```
      （Windows10 の場合は `winpty docker exec -it django.web sh` でコンテナに入ります。）<br />

  16. superuser を作って管理画面にログインできるようにします<br />
    今回も２つの方法があります。好きな方で作って下さい。<br />
    **・方法１：docker-compose run web で作る場合**<br />
      `$ ./docom.sh run -w //code/mysite/ web python manage.py createsuperuser`<br />
      （ここで名前、メールアドレス、パスワードの入力を求められるので、入力します）<br />
      <br />
    **・方法２：サーバーを起動させて docker exec によりコンテナ内に入って作業をする場合**<br />
      ```
      $ ./docom.sh up -d
      $ docker exec -it django.web /bin/sh
      /code $ とプロンプトが出ればコンテナ内に入れています。
      $ cd mysite
      $ python manage.py createsuperuser
      （ここで名前、メールアドレス、パスワードの入力を求められるので、入力します）
      $ exit
      ```
      (Windows10 の場合は `winpty docker exec -it django.web sh` でコンテナに入ります。)<br />

      `./docom.sh up -d` でサーバーを起動させ http://localhost/admin にアクセスし管理画面へログインします。<br />
      「Django管理サイト」が表示されれば完了です。<br />

## 補足

1. Alpine 用の MySQL Clinet として mysql-client をインストールしたところ MySQLが8.0 の場合、mysqlコマンドで認証エラーが起こりました。<br />
Django Webサーバーからは mysqlclient ライブラリを使って MySQL サーバーへ接続しているためこの問題は起こりません。<br />
そのため mysql-client はインストールしていませんが、もしインストールして使う場合には認証方法の変更が必要になります。<br />
具体的には ./db/conf/mysql_my.cnf の２行目にある <br />
`# default_authentication_plugin=mysql_native_password`<br />
の先頭 \# を削除して設定を有効にして下さい。<br />
また、既に起動して DB が作成されている場合には db/data フォルダを丸ごと削除して作り直す必要があります。<br />
(もしくは既存DBの認証方法を変更する事も出来るので必要なら調べて下さい。)<br />
ここは将来的に mysql-client が 8.0 に対応すれば解消されると思われます。<br />

2. Windows10 では docker exec を使う際に winpty docker exec とする必要がありました。<br />
また、/bin/sh や /bin/bash は単に sh , bash と書けば良いようです。<br />

## 終わりに

最後まで読んでいただきありがとうございました。<br />
その他の設定等はソースファイルを参照してください。<br /> 
また駆け足で手順だけの説明になっていて Dockerfile 等の実装については何も書けていません、ご容赦下さい。<br />
そして、理解不足ゆえ不備な点が多々あるかと思います。ご指摘いただければ幸いです。<br />

おっと最後にサーバーを `./docom.sh down` で落とすのをお忘れなく。<br />

以上
