pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'  // Your Docker Hub repository
        K8S_NAMESPACE = 'default'
    }
    
    stages {
        // Stage 1: Clean workspace
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        // Stage 2: Verify tools including Trivy
        stage('Verify Tools') {
            steps {
                script {
                    try {
                        bat 'docker --version'
                        bat 'kubectl version --client'
                        bat 'java -version'
                        // Check if Trivy is installed
                        def trivyInstalled = bat(returnStatus: true, script: 'trivy --version') == 0
                        if (!trivyInstalled) {
                            error("Trivy is not installed. Please install Trivy on the Jenkins agent.")
                        }
                    } catch (Exception e) {
                        error("Required tools verification failed: ${e.getMessage()}")
                    }
                }
            }
        }

        // Stage 3: Checkout code
        stage('Checkout Code') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/MYounas126/DevOps-Project---Connect-Four-App.git'
            }
        }

        // Stage 4: Build Docker image
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        bat 'docker build -t %DOCKER_IMAGE%:latest .'
                    } catch (Exception e) {
                        error("Docker build failed: ${e.getMessage()}")
                    }
                }
            }
        }

        // Stage 5: Scan image (now with better error handling)
        stage('Scan Docker Image') {
            steps {
                script {
                    try {
                        bat 'trivy image --exit-code 0 --severity HIGH,CRITICAL --format table -o trivy-scan.txt %DOCKER_IMAGE%:latest'
                        archiveArtifacts artifacts: 'trivy-scan.txt', allowEmptyArchive: true
                    } catch (Exception e) {
                        echo "WARNING: Trivy scan failed - ${e.getMessage()}"
                        // Continue pipeline despite scan failure
                        // You could also use 'error()' here if you want to fail the build
                    }
                }
            }
        }

        // Stage 6: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    try {
                        withCredentials([[
                            $class: 'UsernamePasswordMultiBinding',
                            credentialsId: 'docker-hub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        ]]) {
                            bat """
                                docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                                docker push %DOCKER_IMAGE%:latest
                                docker logout
                            """
                        }
                    } catch (Exception e) {
                        error("Docker push failed: ${e.getMessage()}")
                    }
                }
            }
        }

        // Stage 7: Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    try {
                        withKubeConfig([
                            credentialsId: 'k8s-config',
                            serverUrl: ''
                        ]) {
                            bat 'kubectl apply -f manifests/'
                        }
                    } catch (Exception e) {
                        error("Kubernetes deployment failed: ${e.getMessage()}")
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images
            script {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    bat 'docker rmi %DOCKER_IMAGE%:latest || echo "Image already removed"'
                }
            }
            
            // Email notification with better error handling
            script {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    emailext (
                        subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                        body: """
                            <p>Build Status: <strong>${currentBuild.currentResult}</strong></p>
                            <p>Docker Image: ${env.DOCKER_IMAGE}:latest</p>
                            <p>Console: <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
                            ${currentBuild.currentResult == 'FAILURE' ? '<p>Failure Reason: Check console output for details</p>' : ''}
                        """,
                        to: 'younasrazakhan786@gmail.com',
                        attachmentsPattern: 'trivy-scan.txt',
                        mimeType: 'text/html'
                    )
                }
            }
        }
    }
}