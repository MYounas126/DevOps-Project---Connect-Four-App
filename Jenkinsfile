pipeline {
    agent any
    tools {
        jdk 'jdk17'       // Make sure this matches exact name in Jenkins Global Tools
        nodejs 'node16'   // Make sure this matches exact name in Jenkins Global Tools
    }
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'  // Changed to your Docker Hub account
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
                sh 'aws --version'
                sh 'kubectl version --client'
                sh 'docker --version'
            }
        }
        
        // Stage 3: Checkout code
        stage('Checkout Code') {                        
            steps {                                       
                git branch: 'main', 
                url: 'https://github.com/MYounas126/Connect-Four-Deployment.git'
            }
        }
        
        // Stage 4: Build Docker image
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }
        
        // Stage 5: Scan Docker image
        stage('Scan Docker Image') { 
            steps { 
                sh "trivy image --format table -o trivy-image-report.html ${DOCKER_IMAGE}:latest" 
            } 
        }
        
        // Stage 6: Push to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }
        
        // Stage 7: Manual approval
        stage('Manual Approval') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input(
                        id: "DeployGate",
                        message: "Approve deployment to Kubernetes?",
                        submitter: "admin"
                    )
                }
            }
        }
        
        // Stage 8: Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig(
                        credentialsId: 'k8s', 
                        namespace: K8S_NAMESPACE
                    ) {
                        sh 'kubectl apply -f manifests/deployment.yaml'
                        sh 'kubectl apply -f manifests/service.yaml'
                    }
                }
            }
        }
        
        // Stage 9: Verify deployment
        stage('Verify Deployment') {
            steps {
                script {
                    withKubeConfig(credentialsId: 'k8s') {
                        sh 'kubectl get pods -n ${K8S_NAMESPACE}'
                        sh 'kubectl get svc -n ${K8S_NAMESPACE}'
                    }
                }
            }
        }
    }
    
    post { 
        always {
            script { 
                // Send email notification
                emailext (
                    subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.result}",
                    body: """
                        <p>Build Result: <strong>${currentBuild.result}</strong></p>
                        <p>Check console output at: <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
                        <p>Docker Image: ${DOCKER_IMAGE}:latest</p>
                    """,
                    to: 'younasrazakhan786@gmail.com',  // Changed to your email
                    attachmentsPattern: 'trivy-image-report.html',
                    mimeType: 'text/html'
                )
                
                // Clean up
                sh 'docker rmi ${DOCKER_IMAGE}:latest || true'
            } 
        } 
    }
}