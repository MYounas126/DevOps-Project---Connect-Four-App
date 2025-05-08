pipeline {
    agent any
    
    tools {
        jdk 'JDK17'
        nodejs 'NodeJS16'
    }
    
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'
        K8S_NAMESPACE = 'default'
        AWS_ACCOUNT_ID = '248189939260'
        AWS_REGION = 'us-east-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/connect-four-deployment"
        EKS_CLUSTER_NAME = 'App-Cluster'
        DEPLOYMENT_FILE = 'manifests/app-deploy.yaml'
        SERVICE_FILE = 'manifests/app-svc.yaml'
        MAX_RETRIES = 3
        RETRY_DELAY = 30 // seconds
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
                                
                                aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                                
                                aws ecr describe-repositories --repository-names connect-four-deployment || aws ecr create-repository --repository-name connect-four-deployment
                                
                                docker push ${ECR_REPO}:latest
                            """
                        }
                    } catch (Exception e) {
                        error("ECR push failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Verify Kubernetes Access') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-creds',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {
                        retry(env.MAX_RETRIES) {
                            bat """
                                aws eks update-kubeconfig --name %EKS_CLUSTER_NAME% --region %AWS_REGION%
                                kubectl cluster-info
                                kubectl get nodes --request-timeout=60s
                            """
                            sleep env.RETRY_DELAY.toInteger()
                        }
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
                        retry(env.MAX_RETRIES) {
                            bat """
                                # Apply Kubernetes manifests with validation disabled
                                kubectl apply -f ${DEPLOYMENT_FILE} --validate=false --request-timeout=120s
                                kubectl apply -f ${SERVICE_FILE} --validate=false --request-timeout=120s
                                
                                # Verify deployment
                                kubectl rollout status deployment/connectfour-deployment -n ${K8S_NAMESPACE} --timeout=180s
                                
                                # Get service details
                                kubectl get svc -n ${K8S_NAMESPACE}
                            """
                            sleep env.RETRY_DELAY.toInteger()
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    bat """
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        kubectl get svc -n ${K8S_NAMESPACE} -o wide
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    bat """
                        docker rmi %DOCKER_IMAGE%:latest || echo 'Image already removed'
                        docker rmi ${ECR_REPO}:latest || echo 'ECR image already removed'
                    """
                    
                    // Archive deployment logs
                    bat "kubectl get all -n ${K8S_NAMESPACE} > k8s-status.txt"
                    archiveArtifacts artifacts: 'k8s-status.txt', allowEmptyArchive: true
                }
                
                emailext (
                    subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                    body: """
                        <h2>Deployment Summary</h2>
                        <p><strong>Status:</strong> ${currentBuild.currentResult}</p>
                        <p><strong>ECR Image:</strong> ${ECR_REPO}:latest</p>
                        <p><strong>EKS Cluster:</strong> ${EKS_CLUSTER_NAME}</p>
                        <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
                        ${currentBuild.currentResult == 'FAILURE' ? '<p style="color:red;">Check the build logs for deployment errors</p>' : ''}
                    """,
                    to: 'younasrazakhan786@gmail.com',
                    attachmentsPattern: 'trivy-scan.txt, k8s-status.txt',
                    mimeType: 'text/html'
                )
            }
        }
    }
}