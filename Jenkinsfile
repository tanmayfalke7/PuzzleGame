
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

                        // Remove any old test container
                        sh """
                            docker rm -f ${TEST_CONTAINER} || true
                        """

                        // Start temporary container
                        sh """
                            docker run -d \
                                --name ${TEST_CONTAINER} \
                                ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        """

                        // Give Nginx time to start
                        sleep(time: 5, unit: 'SECONDS')

                        // Check HTTP response from Nginx
                        def healthCheck = sh(
                            script: """
                                docker exec ${TEST_CONTAINER} \
                                wget -S -O /dev/null \
                                http://127.0.0.1:80 2>&1 || true
                            """,
                            returnStdout: true
                        ).trim()

                        echo "Health Check Response:"
                        echo healthCheck

                        // Validate HTTP 200 response
                        if (!(healthCheck =~ /HTTP\\/[0-9.]+\\s+200\\b/)) {
                            error("Application health check failed!")
                        }

                        echo 'Application health check PASSED!'

                    } finally {

                        // Always remove temporary container
                        echo 'Cleaning up test container...'

                        sh """
                            docker rm -f ${TEST_CONTAINER} || true
                        """
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

                dir('terraform') {

                    // Initialize Terraform
                    sh 'terraform init -input=false'

                    // Validate Terraform configuration
                    sh 'terraform validate'

                    // Generate execution plan
                    sh 'terraform plan -input=false -out=tfplan'

                    echo 'Terraform plan generated successfully.'
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
