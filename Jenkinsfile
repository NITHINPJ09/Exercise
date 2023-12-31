pipeline {
    agent any 
    tools {
        terraform 'Terraform-1.4.2'
    }
    stages {
        stage('Run CI?') {
          steps {
            script {
              sh 'git log -1'
              if (sh(script: "git log -1 | grep '.*\\[ci skip\\].*'", returnStatus: true) == 0) {
                currentBuild.result = 'NOT_BUILT'
                error "'[ci skip]' found in git commit message. Aborting..."
              }
            }
          }
        } 
        stage('---Test---') {
            steps {
                sh 'grep -i "Hello" index.html'
            }
        }
        stage('---Infrastructure Provisioning---') { 
            environment {
                AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
                AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
            }
            steps {
                sh '''terraform init
                    terraform apply -auto-approve
                    chmod 600 private.pem'''
                script {
                    def IP = sh(script: "terraform output public_ip", returnStdout: true).trim()
                    env.PUBLIC_IP = IP.replaceAll('"','')
                }
            }
        }        
        stage('---Installation---') {
            steps {
                sleep time: 5, unit: 'SECONDS'
                sh '''ssh -i private.pem -o StrictHostKeyChecking=accept-new -T ubuntu@$PUBLIC_IP <<EOF
                    whoami
                    sudo apt update
                    sudo snap install docker
                    exit
                    EOF'''
            }
        }  
        stage('---Configuration---') {
            steps {
                sh '''ssh -i private.pem -o StrictHostKeyChecking=accept-new -T ubuntu@$PUBLIC_IP <<EOF
                    sudo groupadd docker
                    sudo usermod -aG docker ubuntu
                    newgrp docker
                    sudo chown root:docker /var/run/docker.sock
                    exit
                    exit
                    EOF'''
            }
        }
        stage('---Deployment---') {
            steps {
                sh '''ssh -i private.pem -o StrictHostKeyChecking=accept-new -T ubuntu@$PUBLIC_IP <<EOF
                    if [ -d "/home/ubuntu/demo" ]
                    then 
                        echo "Demo folder is already there."
                    else 
                        mkdir demo
                    fi
                    exit
                    EOF'''
                sh '''scp -i private.pem  -o StrictHostKeyChecking=accept-new -r ./index.html ./css ./Dockerfile ubuntu@$PUBLIC_IP:/home/ubuntu/demo'''
                sh '''ssh -i private.pem -o StrictHostKeyChecking=accept-new -T ubuntu@$PUBLIC_IP <<EOF
                    cd demo
                    if docker ps | grep -q 'myApp'
                    then 
                        echo "Stopping and removing the container."
                        docker stop myApp
                        docker rm myApp 
                        docker rmi website                        
                    fi
                    docker build -t website .
                    docker run -d --restart always -p 80:80 --name myApp website
                    exit
                    EOF'''
            }
        } 
    }
}
