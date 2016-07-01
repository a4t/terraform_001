#!/bin/sh -e
S3_BUCKET=bucket=hogehogefugafugapiyopiyomogemoge

for key in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
  if [ -z "$(eval 'echo $'$key)" ]; then
    echo Environment ${key} must setting
    exit
  fi
done

cd /terraform

/usr/bin/terraform remote config \
  -backend=s3 \
  -backend-config="bucket=${S3_BUCKET}" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=ap-northeast-1" \

/usr/bin/terraform get
/usr/bin/terraform $@
/usr/bin/terraform remote push
