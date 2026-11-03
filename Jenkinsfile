pipeline {
    agent any

    environment {
        IMAGE_NAME = 'puzzle-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        REGISTRY   = 'docker.io/tanmayfalke7'
    }

    stages {
        stage('Source Code Checkout') {
            steps {
                echo '=== Stage 1: Checking out source code from Git ==='
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '=== Stage 2: Building Docker Container Image ==='
                script {
                    dockerImage = docker.build("${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}", ".")
                    docker.build("${REGISTRY}/${IMAGE_NAME}:latest", ".")
                }
            }
        }

        stage('Test Application Container') {
            steps {
                echo '=== Stage 3: Running Automated Container Health Check ==='
                script {
                    // Start temporary container for validation
                    sh "docker run -d --name test-puzzle -p 8089:80 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sleep 5
                    
                    // Verify server responds with HTTP 200
                    def statusCode = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8089",
                        returnStdout: true
                    ).trim()

                    // Cleanup test container
                    sh "docker stop test-puzzle && docker rm test-puzzle"

                    if (statusCode != '200') {
                        error("Health check failed! Server returned HTTP ${statusCode}")
                    } else {
                        echo "Health check passed! HTTP status code: ${statusCode}"
                    }
                }
            }
        }

        stage('Terraform Provisioning') {
            steps {
                echo '=== Stage 4: Provisioning Infrastructure via IaC ==='
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                    // Uncomment line below to auto-apply in real cloud envs:
                    // sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Deploy Application') {
            steps {
                echo '=== Stage 5: Deploying Container to Production Environment ==='
                script {
                    // Stop existing production container if running
                    sh 'docker stop puzzle-prod || true'
                    sh 'docker rm puzzle-prod || true'
                    
                    // Run production deployment
                    sh "docker run -d --name puzzle-prod -p 8080:80 ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace artifact buffers...'
            cleanWs()
        }
        success {
            echo 'CI/CD Pipeline executed successfully!'
        }
        failure {
            echo 'CI/CD Pipeline failed during execution. Inspect stage logs.'
        }
    }
}