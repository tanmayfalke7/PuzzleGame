
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        IMAGE_NAME = 'puzzle-app'
        REGISTRY   = 'tanmayfalke7'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        TEST_CONTAINER = 'test-puzzle'
        PROD_CONTAINER = 'puzzle-prod'
        APP_PORT = '8080'
    }

    stages {

        // ==========================================
        // STAGE 1: SOURCE CODE CHECKOUT
        // ==========================================

        stage('Source Code Checkout') {
            steps {
                echo '=== Stage 1: Checking out source code ==='

                checkout scm

                sh 'echo "Source code checkout completed."'
                sh 'ls -la'
            }
        }


        // ==========================================
        // STAGE 2: BUILD DOCKER IMAGE
        // ==========================================

        stage('Build Docker Image') {
            steps {
                echo '=== Stage 2: Building Docker Image ==='

                sh """
                    docker build \
                        -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${REGISTRY}/${IMAGE_NAME}:latest .
                """

                sh 'docker images'
            }
        }


        // ==========================================
        // STAGE 3: TEST APPLICATION CONTAINER
        // ==========================================

        
stage('Test Application Container') {
    steps {
        echo '=== Stage 3: Testing Application Container ==='

        script {
            try {

                // Step 1: Remove old test container
                sh 'docker rm -f test-puzzle || true'

                // Step 2: Start new container
                sh """
                    docker run -d \
                    --name test-puzzle \
                    ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """

                // Step 3: Wait for Nginx
                sleep(time: 5, unit: 'SECONDS')

                // Step 4: Extract HTTP status code
                def statusCode = sh(
                    script: """
                        docker exec test-puzzle \
                        wget -S -O /dev/null \
                        http://127.0.0.1:80 2>&1 \
                        | awk '/HTTP\\// {print \$2}' \
                        | tail -1
                    """,
                    returnStdout: true
                ).trim()

                echo "HTTP Status Code: ${statusCode}"

                // Step 5: Validate
                if (statusCode == '200') {

                    echo 'SUCCESS: Application is healthy!'

                } else {

                    error("Health check failed! HTTP Status: ${statusCode}")

                }

            } finally {

                // Step 6: Cleanup
                echo 'Removing temporary test container...'

                sh 'docker rm -f test-puzzle || true'
            }
        }
    }
}



        // ==========================================
        // STAGE 4: TERRAFORM PROVISIONING
        // ==========================================

        stage('Terraform Provisioning') {
    steps {
        echo '=== Stage 4: Terraform Infrastructure Validation ==='

        withCredentials([
            string(credentialsId: 'aws-access-key',
                   variable: 'AWS_ACCESS_KEY_ID'),

            string(credentialsId: 'aws-secret-key',
                   variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
            dir('terraform') {
                sh '''
                    terraform init -input=false
                    terraform validate
                    terraform plan -input=false -out=tfplan
                '''
            }
        }
    }
}


        // ==========================================
        // STAGE 5: DEPLOY APPLICATION
        // ==========================================

        stage('Deploy Application') {
            steps {
                echo '=== Stage 5: Deploying Application ==='

                script {

                    // Remove previous production container
                    sh """
                        docker rm -f ${PROD_CONTAINER} || true
                    """

                    // Deploy newly tested image
                    sh """
                        docker run -d \
                            --name ${PROD_CONTAINER} \
                            --restart unless-stopped \
                            -p ${APP_PORT}:80 \
                            ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """

                    // Verify deployment
                    sh """
                        docker ps --filter name=${PROD_CONTAINER}
                    """

                    echo "Application deployed on port ${APP_PORT}."
                }
            }
        }
    }


    // ==========================================
    // POST BUILD ACTIONS
    // ==========================================

    post {

        always {
            echo '=== Pipeline Cleanup ==='

            // Ensure temporary container is removed
            sh 'docker rm -f test-puzzle || true'

            // Clean Jenkins workspace
            cleanWs()
        }

        success {
            echo '======================================'
            echo 'CI/CD PIPELINE EXECUTED SUCCESSFULLY!'
            echo '======================================'

            echo 'Application URL: http://localhost:8080'
        }

        failure {
            echo '======================================'
            echo 'CI/CD PIPELINE FAILED!'
            echo 'Check the failed stage in Jenkins.'
            echo '======================================'
        }
    }
}
