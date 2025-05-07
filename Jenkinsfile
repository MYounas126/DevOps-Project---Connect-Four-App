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

        // Stage 2: Verify tools
        stage('Verify Tools') {
            steps {
                bat 'docker --version'
                bat 'kubectl version --client'
                bat 'java -version'
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
                bat 'docker build -t %DOCKER_IMAGE%:latest .'
            }
        }

        // Stage 5: Scan image
        stage('Scan Docker Image') {
            steps {
                bat 'trivy image --exit-code 0 --severity HIGH,CRITICAL --format table -o trivy-scan.txt %DOCKER_IMAGE%:latest'
                archiveArtifacts artifacts: 'trivy-scan.txt', allowEmptyArchive: true
            }
        }

        // Stage 6: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
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
                }
            }
        }

        // Stage 7: Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig([
                        credentialsId: 'k8s-config',
                        serverUrl: ''
                    ]) {
                        bat 'kubectl apply -f manifests/'
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images
            bat 'docker rmi %DOCKER_IMAGE%:latest || echo "Image already removed"'
            
            // Email notification
            emailext (
                subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                body: """
                    <p>Build Status: <strong>${currentBuild.currentResult}</strong></p>
                    <p>Docker Image: ${env.DOCKER_IMAGE}:latest</p>
                    <p>Console: <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
                """,
                to: 'younasrazakhan786@gmail.com',
                attachmentsPattern: 'trivy-scan.txt',
                mimeType: 'text/html'
            )
        }
    }
}