## Hashicorpのbest-practicesから学ぶTerraformの使い方

## これなんだ？

Terraformをちょっと上手に使うためのテクニックというかコツです。
個人的には上手にHashicorpツールを使う能力を橋本力と呼んでます。

今回参考にしたものはこちらになります。
https://github.com/hashicorp/best-practices/

また今回動作させたコードも置いておきます。

## 前提
Terraformも一つの言語と思ってください。
いいコードとは、変数のスコープは短く、同じ処理を何度も書かないことです。
これはTerraformでも同様です、できるだけ綺麗なコードを書くことを意識してください。

## Terraformの課題
- そもそもTerraformのバージョンが違って動かない
  - バージョンアップによって微妙な差分が発生し、何も変更ないのに変更箇所が出るケースがある (例: 指定パラメータが `true -> 1` に変更とか)
- s3でtfstateを管理する場合、applyした後にpushをする必要がある
  - 各エンジニアが毎回実行するのであれば問題ないが、忘れるケースがあるためそもそもPushコマンドをDocker側でフォローして毎回Pushする
- null_resourceでaws cliのコマンド使うとか
  - 人によってはローカルに入ってなかったり、バージョンが違うため動かないとか

### 解決策
Dockerを使います。
あんまりこの辺りは深く説明しませんが、こんな感じにすれば先ほどの3つの問題が解決します。

```Dockerfile
FROM alpine:3.3

ENV TERRAFORM_VERSION=0.6.15

RUN apk update && \
    apk add bash \
    ca-certificates \
    git \
    openssl \
    zip \
    unzip \
    wget \
    python \
    py-pip \
    py-setuptools \
    ca-certificates \
    groff \
    less && \
    pip install awscli && \
    wget -P /tmp https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

ADD ./scripts /scripts

ENTRYPOINT ["/scripts/terraform.sh"]

CMD ["--help"]
```

```terraform.sh
#!/bin/sh

/usr/bin/terraform remote config \
  -backend=s3 \
  -backend-config="bucket=hogehogefugafugapiyopiyomogemoge" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=ap-northeast-1" \

/usr/bin/terraform get
/usr/bin/terraform $@
/usr/bin/terraform remote push
```

毎回必ずterraform getとterraform remote pushをしてくれます。
あとは `$@` の部分に任意のコマンドが入ってくれます。

Terraformコマンドは `docker run terraform plan` とかを使うことになります。
環境変数とか面倒なところありますが、docker-compose使って解決するといいです。

## コードを綺麗にする
最初にみたbest-practicesを見るとわかるのですが、terraformが階層が深くなっています。
moduleを使って各tfファイルを繋いでいます。
ディレクトリ構造はこの辺りを参考にするといいと思います。(ファイル多いので一部略してます)


```
best-practices
├── LICENSE
├── README.md
├── packer
└── terraform
    ├── empty.tf
    ├── modules
    │   └── aws
    │       ├── compute
    │       ├── data
    │       ├── network
    │       └── util
    │           ├── artifact
    │           │   └── artifact.tf
    │           ├── deploy
    │           │   └── deploy.tf
    │           ├── iam
    │           │   └── iam.tf
    │           └── website
    │               └── website.tf
    └── providers
        └── aws
            ├── README.md
            ├── us_east_1_prod
            │   ├── terraform.tfvars
            │   └── us_east_1_prod.tf
            └── us_east_1_staging
                ├── terraform.tfvars
                └── us_east_1_staging.tf
```

compute, data, network, util とそれぞれの役割をしっかりディレクトリで切られてるのでコードを追いやすいです。
1ディレクトリにごちゃごちゃ置いてしまうのがよくあるパターンだと思います。
security_group_web.tf、security_group_mysql.tf、security_group_elb.tf、ec2_web.tfとかこんな感じに最初は自分も分けてました。

### 解決策
moduleを使うとこの辺は綺麗に書けます。
例えば今回はdeployサーバからcapistranoを実行するために `deploy -> [port22] -> app を開放するとします。
こんな感じにするとコードの重複も避けれますし、変更箇所も減るかと思います。

```security_group.tf
module "security_group" {
  source = "./modules/security_group"

  vpc_id       = "${aws_vpc.vpc.id}"
  deploy_sg    = "${aws_security_group.deploy.id}"

  app_sg_count = "3" # module内のcountでlengthとか使うとsyntax errorが出るため
  app_sg_list  = [
    "${aws_security_group.app1.id}",
    "${aws_security_group.app2.id}",
    "${aws_security_group.app3.id}"
  ]
}
```

```./modules/security_group
variable "deploy_sg"    {}
variable "vpc_id"       {}
variable "app_sg_count" {}
variable "app_sg_list"  { default = [] }

resource "aws_security_group_rule" "attach" {
  count = "${var.app_sg_count}"

  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  source_security_group_id = "${var.deploy_sg}"

  security_group_id = "${element(var.app_sg_list, count.index)}"
}
```

## 最後に
とは言っても既存のコードを書き換えるのは超労力いるので無理はしないでください。
subnetとかを破壊するのは危険ですし、tfstateのjsonを目で追うのはつらいです。