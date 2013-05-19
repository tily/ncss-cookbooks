# ncss-cookbooks コマンド

## 概要

Chef の Cookbooks を一発で NIFTYCloud クラウドストレージにアップロードするコマンドです。

## インストール

    gem install ncss-cookbooks

## コマンド一覧

    $ ncss-cookbooks  
    Commands:
      ncss-cookbooks create <bucket_name>  # create ncss bucket
      ncss-cookbooks help [COMMAND]        # Describe available commands or one specific command
      ncss-cookbooks upload <bucket_name>  # upload . to ncss bucket
    
    Options:
      [--access-key-id=ACCESS_KEY_ID]          
      [--secret-access-key=SECRET_ACCESS_KEY]  

## 使い方

まずはアップロードしたい cookbooks を用意します。

    $ mkdir my-cookbooks
    $ cd my-cookbooks
    $ echo "cookbook_path '.'" > knife.rb
    $ knife cookbook create hello-world
    ** Creating cookbook hello-world
    ** Creating README for cookbook: hello-world
    ** Creating CHANGELOG for cookbook: hello-world
    ** Creating metadata for cookbook: hello-world

次に同じディレクトリの中に、
cookbooks のバージョン情報が書いてある VERSION ファイルを作成します。

    $ echo "0.0.0" > VERSION

さらに環境変数で API キーを設定します。

    $ export ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
    $ export SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

これで準備完了です。cookbooks ディレクトリの中で ncss-cookbooks コマンドを打ちます。

ncss-cookbooks create でバケットを作成します。

    $ ncss-cookbooks create my-bucket

ncss-cookbooks upload で作成したバケットに cookbooks をアップロードします。

    $ ncss-cookbooks upload my-bucket
    Version is v0.0.1
    Creating directory /tmp/ncss-cookbooks-20130519-30448-2im9m1/cookbooks/
    Copying files from /home/tily/dev/ncss-cookbooks to /tmp/ncss-cookbooks-20130519-30448-2im9m1/cookbooks/
      Excluded /home/tily/dev/ncss-cookbooks/.git
    Archiving /tmp/ncss-cookbooks-20130519-30448-2im9m1/cookbooks/ to /tmp/ncss-cookbooks-20130519-30448-2im9m1/cookbooks.tgz
    Uploading /tmp/ncss-cookbooks-20130519-30448-2im9m1/cookbooks.tgz to bucket:my-bucket, object:v0.0.1/cookbooks.tgz
    Temporary directory /tmp/ncss-cookbooks-20130519-30448-2im9m1 will be deleted automatically
    Uploaded to https://my-bucket.ncss.nifty.com/v0.0.1/cookbooks.tgz

発行された URL は chef-solo の -r オプションで利用することができます。

    $ chef-solo -j node.json -r https://my-bucket.ncss.nifty.com/v0.0.0/cookbooks.tgz
