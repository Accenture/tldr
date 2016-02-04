#!/bin/bash

#!/bin/bash

if [[ "$AWS_ACCESS_KEY_ID" == "" || "$AWS_SECRET_ACCESS_KEY" == "" || "$AWS_DEFAULT_REGION" == "" || "" ]]; then
	echo "ERROR: please provide environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION"
	exit 1
fi

if [[ "$1" == "" ]] ; then
	echo "usage: $0 [plan/apply/destroy/...]"
	exit 1
fi

TERRAFORM_ACTION=$1

terraform $1
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Terraform failed"
  exit 1
fi

echo 'Done'
exit 0