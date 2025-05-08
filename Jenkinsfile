pipeline {
    agent any
    
    tools {
        jdk 'JDK17'
        nodejs 'NodeJS16'
    }
    
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'
        K8S_NAMESPACE = 'default'
        AWS_ACCOUNT_ID = '248189939260' // Replace with your AWS account ID
        AWS_REGION = 'us-east-1' // Replace with your AWS region
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/connect-four-deployment"
        EKS_CLUSTER_NAME = 'App-Cluster' // Replace with your EKS cluster name
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Verify Tools') {
            steps {
                script {
                    try {
                        bat 'docker --version'
                        bat 'kubectl version --client'
                        bat 'java -version'
                        bat 'aws --version || echo "AWS CLI not found"'
                        
                        def trivyInstalled = bat(returnStatus: true, script: 'trivy --version || echo "Trivy not found"') == 0
                        if (!trivyInstalled) {
                            echo "WARNING: Trivy is not installed. Image scanning will be skipped."
                            env.SKIP_TRIVY = 'true'
                        }
                    } catch (Exception e) {
                        error("Required tools verification failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/MYounas126/DevOps-Project---Connect-Four-App.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        bat 'docker build -t %DOCKER_IMAGE%:latest .'
                        bat "docker tag %DOCKER_IMAGE%:latest ${ECR_REPO}:latest"
                    } catch (Exception e) {
                        error("Docker build failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Scan Docker Image') {
            when {
                expression { env.SKIP_TRIVY != 'true' }
            }
            steps {
                script {
                    try {
                        bat 'trivy image --exit-code 0 --severity HIGH,CRITICAL --format table -o trivy-scan.txt %DOCKER_IMAGE%:latest'
                        archiveArtifacts artifacts: 'trivy-scan.txt', allowEmptyArchive: true
                    } catch (Exception e) {
                        echo "WARNING: Trivy scan failed - ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    try {
                        // Using withCredentials instead of withAWS
                        withCredentials([
                            usernamePassword(
                                credentialsId: 'aws-creds',
                                usernameVariable: 'AWS_ACCESS_KEY_ID',
                                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                            )
                        ]) {
                            // Configure AWS CLI
                            bat """
                                aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
                                aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
                                aws configure set region %AWS_REGION%
                            """
                            
                            // Login to ECR
                            bat "aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                            
                            // Create ECR repository if not exists
                            bat "aws ecr describe-repositories --repository-names connect-four-deployment || aws ecr create-repository --repository-name connect-four-deployment"
                            
                            // Push to ECR
                            bat "docker push ${ECR_REPO}:latest"
                        }
                    } catch (Exception e) {
                        error("ECR push failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Deploy to EKS') {
    steps {
        script {
            withCredentials([
                usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )
            ]) {
                bat """
                    aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
                    aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
                    aws configure set region %AWS_REGION%
                    
                    aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION%
                    
                    # Add retry logic for kubectl commands
                    kubectl get nodes --request-timeout=30s || sleep 30 && kubectl get nodes
                    kubectl apply -f manifests/ --validate=false --request-timeout=60s
                """
            }
        }
    }
}
    }

    post {
        always {
            script {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    bat "docker rmi %DOCKER_IMAGE%:latest || echo 'Image already removed'"
                    bat "docker rmi ${ECR_REPO}:latest || echo 'ECR image already removed'"
                }
                
                emailext (
                    subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                    body: """
                        <p>Build Status: <strong>${currentBuild.currentResult}</strong></p>
                        <p>AWS ECR Image: ${ECR_REPO}:latest</p>
                        <p>Console: <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
                    """,
                    to: 'younasrazakhan786@gmail.com',
                    attachmentsPattern: 'trivy-scan.txt',
                    mimeType: 'text/html'
                )
            }
        }
    }
}