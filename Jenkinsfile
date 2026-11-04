pipeline {
    agent any

    environment {
        IMAGE_NAME = 'puzzle-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        REGISTRY   = 'tanmayfalke7' // Your Docker Hub username
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
                    sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Test Application Container') {
            steps {
                echo '=== Stage 3: Running Automated Container Health Check ==='
                script {
                    // 1. Run temporary test container
                    sh "docker run -d --name test-puzzle tanmayfalke7/puzzle-app:${IMAGE_TAG}"
                    sleep 3
                    
                    // 2. Perform health check directly inside the container
                    def statusCode = sh(
                        script: "docker exec test-puzzle curl -s -o /dev/null -w '%{http_code}' http://localhost:80",
                        returnStdout: true
                    ).trim()

                    // 3. Clean up test container
                    sh "docker stop test-puzzle && docker rm test-puzzle"

                    // 4. Validate response code
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
                }
            }
        }

        stage('Deploy Application') {
            steps {
                echo '=== Stage 5: Deploying Container to Production Environment ==='
                script {
                    sh 'docker stop puzzle-prod || true'
                    sh 'docker rm puzzle-prod || true'
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