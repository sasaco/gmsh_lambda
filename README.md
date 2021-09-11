# 概要

## AWS公式リファレンス 
https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/images-create.html#images-create-from-alt

記事 [第一回 コンテナ Lambda の”いろは”、AWS CLI でのデプロイに挑戦 !](https://aws.amazon.com/jp/builders-flash/202103/new-lambda-container-development/?awsf.filter-name=*all) を参考に

windows10 で AWS Lambda 関数を Docker コンテナを使ってビルド & デプロイ する方法を書きました

AWS Lambda 関数を Docker コンテナを使ってビルド & デプロイ するには以下の３ステップが必要です

1.**Docker イメージ**を作成する
2.**Docker イメージ**を **Amazon ECR リポジトリ** にプッシュする
3.**Lambda関数**に **Amazon ECR リポジトリ**(の Docker イメージ) から ビルドする

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/f9b2a7ab-0ccf-4df5-93c1-1ef47797a046.png)


# 前提条件

### Docker Desktop がインストールされていること

この記事は Windows10 上で Docker を用いて操作しています。

この記事の作業はローカル環境に Docker Desktop がインストールされていることを前提で進めます。インストールされていない場合は、インストールしてから進めてください。

### Amazon CLI がインストールされていること

Amazon CLI
https://aws.amazon.com/jp/cli/

aws configure (初期化) が済んでいること

```powershell
> aws configure
AWS Access Key ID [None]: ATI********CS
AWS Secret Access Key [None]: ***erg***sdfg***bs1sderg**
Default region name [None]: ap-northeast-1
Default output format [None]: json
```

# 実装

## 1.Docker イメージを作成する手順

### 手順1-1: ２つのテキストファイルを用意する

作業するフォルダを決めて
以下の２つのテキストファイルを作成しましょう

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/cac7bee0-e795-a9a5-bd32-94828e98bdfd.png)

それぞれのファイルの中身は以下の通りとします。

```python:app.py
import json

def handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "hello world",
            }
        ),
    }
```

```Dockerfile:Dockerfile
FROM public.ecr.aws/lambda/python:3.8
COPY app.py   ./
CMD ["app.handler"]  
```

>解説
FROM 命令で public.ecr.aws/lambda/python:3.8 と ECR の AWS 公式の公開イメージを指定していますが、amazon/aws-lambda-python:3.8 のように docker hub のイメージを参照することも可能です。
　
COPY コマンドでローカルに配置されている Lambda 関数本体である app.py ファイルをイメージにコピーしています。そして CMD で Lambda 関数のハンドラーを渡しています。

### 手順1-2:  Dockerfile 元にビルド

 Dockerfile を元にビルドしてみましょう。
コマンド `docker build -t func1 .` を実行します。

```powershell
> docker build -t func1 .

[+] Building 19.2s (7/7) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                      
=> => naming to docker.io/library/func1                                                                                                                                                                       

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
```

ビルド成功しました

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/437f5625-72de-c83d-3006-890bf9389b2d.png)


### 手順1-3 実行してみる

```powershell
docker run -it func1:latest    
```

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/43ac5964-b211-7b9a-8e6e-dc719f712c0a.png)


### 手順1-4 python3 を実行してみる

2021.08.22 現在 import gmsh に失敗するので
この issue に基づいて

https://gitlab.onelab.info/gmsh/gmsh/-/issues/1023

下記を実行

```python
import sys
sys.path.append('/usr/local/lib/python3.8/site-packages/gmsh-4.8.4-Linux64-sdk/lib')
```

## 2.Docker イメージを Amazon ECR にプッシュする手順

### 手順2-1: Amazon ECR に今回作成する Lambda 関数のイメージ用のリポジトリを作成します。

さて、ここから Amazon ECR に今回作成する Lambda 関数のイメージ用のリポジトリを作成します。

> Amazon ECR とは
Elastic Container Registry の略で
Dockerのコンテナイメージを保存しておくためのレジストリで、
Dockerコンテナイメージを保存・管理・デプロイが簡単に出来ます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/0f128503-e036-c122-60c8-1fff6b2579cc.png)


### 手順2-2: Docker に リポジトリの URI を含めたタグを付与します。

ECR 上にリポジトリが作成されたら、リポジトリの URI を含めたタグを付与します。

```powershell
docker tag func1:latest 533291615220.dkr.ecr.ap-northeast-1.amazonaws.com/func1:latest
```

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/21dbf5b9-930c-40c4-df97-dbea78b5ab57.png)

Docker Desktop の Images に追加されます。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/24a6dc2a-ebe2-20f9-351a-81ae48be68cd.png)


### 手順2-3:リポジトリに push する前に、ECR にログインします。

```powershell
> aws ecr get-login-password | docker login --username AWS --password-stdin 533291615220.dkr.ecr.ap-northeast-1.amazonaws.com
Login Succeeded
```


### 手順2-4:リポジトリに push 

リポジトリに push しましょう。

```powershell
PS> docker push 533291615220.dkr.ecr.ap-northeast-1.amazonaws.com/func1:latest
The push refers to repository [533291615220.dkr.ecr.ap-northeast-1.amazonaws.com/func1]
29fe8a4ae381: Pushed 
20b4eff3dd4d: Pushing  68.11MB/92.13MB
11284767d41d: Pushing  87.48MB/199.7MB
d6fa53d6caa6: Pushed 
b09e76f63d5d: Pushed 
0acabcf564c7: Pushed 
f2342b1247df: Pushing  125.9MB/294.9MB
latest: digest: sha256:123*************************************789
```

push が完了すると、ダイジェストが発行されるので、覚えておく

AWS コンソールで確認すると cocker イメージが Amaxon ECR リポジトリ にアップロードされたのが確認できる
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/509905c8-f589-b776-a30e-55dd0914d069.png)



## 3.Lambda関数に Amazon ECR リポジトリ(の Docker イメージ) から ビルドする手順

### 手順3-1: AWS Lambda ダッシュボードから 関数作成 ボタンをクリックする

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/dd4053da-a4b5-7857-9360-dcb11fc83e71.png)

### 手順3-2: コンテナイメージから作成

ここから、Lambda 関数をコンテナイメージを利用して作成していきますが、AWS Lambda のコンテナサポートで、—package-type を指定できるようになりました。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/6d7e1c88-4969-86ab-638b-2daa31d9d2e7.png)

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/61fb0ee6-f60f-9031-fc04-1cd5c3b53387.png)

できました 今回の Lambda関数名 は, **docker_test** としました

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/0fa08f3e-b842-de4e-7c7d-a044a42cb4b3.png)


### 手順3-3:作成された関数を実行確認

そしていよいよ実行することができます。作成された関数を実行してみましょう。

```powershell
> aws lambda invoke --function-name docer_test output ; cat output
```

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/142847/f5406cf3-3573-fdb1-0067-d6ea7f0b1dad.png)

正常に返ってきました！！
