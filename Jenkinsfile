pipeline {
    agent any

    options { skipDefaultCheckout(true); timestamps() }

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '3.111.31.113', description: 'Public IP or DNS name of the Terraform EC2 instance')
        string(name: 'INSTANCE_ID', defaultValue: 'i-07d46be5a9b40ea9e', description: 'EC2 instance ID used by EC2 Instance Connect')
        string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region containing the EC2 instance')
    }

    environment {
        IMAGE_NAME     = 'puzzle-app'
        PROD_CONTAINER = 'puzzle-prod'
        DEPLOY_USER    = 'ec2-user'
    }

    stages {
        stage('Checkout') { steps { checkout scm } }

        stage('Validate prerequisites') {
            steps {
                sh '''
                    set -eu
                    command -v docker
                    command -v aws
                    command -v ssh
                    command -v ssh-keygen
                    command -v curl
                '''
            }
        }

        stage('Build image') {
            steps {
                script { env.IMAGE_REF = "${IMAGE_NAME}:${BUILD_NUMBER}" }
                sh 'docker build --pull -t "$IMAGE_REF" .'
            }
        }

        stage('Container smoke test') {
            steps {
                sh '''
                    set -eu
                    docker rm -f puzzle-smoke-test >/dev/null 2>&1 || true
                    docker run -d --name puzzle-smoke-test "$IMAGE_REF"
                    trap 'docker rm -f puzzle-smoke-test >/dev/null 2>&1 || true' EXIT
                    sleep 3
                    docker exec puzzle-smoke-test wget -q -O /dev/null http://127.0.0.1/
                '''
            }
        }

        stage('Validate Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                        set -eu
                        terraform init -backend=false -input=false
                        terraform validate
                    '''
                }
            }
        }

        stage('Verify deployment target') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        set -eu
                        aws ec2 describe-instances \
                          --region "$AWS_REGION" \
                          --instance-ids "$INSTANCE_ID" \
                          --query 'Reservations[0].Instances[0].State.Name' \
                          --output text | grep -qx running
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    set -eu
                    key_dir="$(mktemp -d)"
                    trap 'rm -rf "$key_dir"' EXIT
                    key_file="$key_dir/deploy_key"
                    ssh-keygen -q -t ed25519 -N '' -f "$key_file"

                    # EC2 Instance Connect keys expire after 60 seconds. This avoids
                    # storing a long-lived SSH private key in Jenkins.
                    aws ec2-instance-connect send-ssh-public-key \
                      --region "$AWS_REGION" \
                      --availability-zone "$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' --output text)" \
                      --instance-id "$INSTANCE_ID" \
                      --instance-os-user "$DEPLOY_USER" \
                      --ssh-public-key "file://$key_file.pub" >/dev/null

                    ssh_opts="-i $key_file -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15"
                    ssh $ssh_opts "$DEPLOY_USER@$DEPLOY_HOST" '\
                      if ! command -v docker >/dev/null 2>&1; then sudo dnf install -y docker; fi; \
                      sudo systemctl enable --now docker'

                    docker save "$IMAGE_REF" | ssh $ssh_opts "$DEPLOY_USER@$DEPLOY_HOST" 'sudo docker load'

                    ssh $ssh_opts "$DEPLOY_USER@$DEPLOY_HOST" "\
                      sudo docker rm -f '$PROD_CONTAINER' >/dev/null 2>&1 || true; \
                      sudo docker run -d --name '$PROD_CONTAINER' --restart unless-stopped -p 80:80 '$IMAGE_REF'; \
                      sleep 3; \
                      sudo docker exec '$PROD_CONTAINER' wget -q -O /dev/null http://127.0.0.1/"
                    '''
                }
            }
        }

        stage('Verify public endpoint') {
            steps {
                sh 'curl --fail --silent --show-error --retry 5 "http://$DEPLOY_HOST/" >/dev/null'
            }
        }
    }

    post {
        always {
            sh 'docker rm -f puzzle-smoke-test >/dev/null 2>&1 || true'
            cleanWs(deleteDirs: true, notFailBuild: true)
        }
        success { echo "Deployment succeeded: http://${params.DEPLOY_HOST}/" }
    }
}
