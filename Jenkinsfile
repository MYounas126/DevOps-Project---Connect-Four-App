pipeline {
    agent any
    
    tools {
        jdk 'JDK17'  // Make sure this tool is configured in Jenkins
        nodejs 'NodeJS16'  // Make sure this tool is configured in Jenkins
        // Comment out sonar-scanner if not needed or configure it in Jenkins
        // sonarScanner 'sonar-scanner' 
    }
    
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'
        K8S_NAMESPACE = 'default'
        // Only set SCANNER_HOME if you have SonarQube configured
        // SCANNER_HOME = tool 'sonar-scanner'
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
                        
                        // Make Trivy check optional
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

        /* Comment out SonarQube stages if not needed
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    bat 'sonar-scanner -Dsonar.projectName=connect-four -Dsonar.projectKey=connect-four'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        */

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

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // First verify kubectl is working
                    bat 'kubectl version --client'
            
                    // Then try to apply your manifests
                     bat 'kubectl apply -f manifests/'
                     bat 'kubectl get services'
                    /*try {
                        withKubeConfig([
                            credentialsId: 'k8s-config',
                            serverUrl: ''
                        ]) {
                            bat 'kubectl apply -f manifests/'
                        }
                    } catch (Exception e) {
                        error("Kubernetes deployment failed: ${e.getMessage()}")
                    }*/
                }
            }
        }
    }

    post {
        always {
            script {
                // Only try to clean up if we're in a node context
                if (env.NODE_NAME != null) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        bat 'docker rmi %DOCKER_IMAGE%:latest || echo "Image already removed"'
                    }
                }
                
                // Improved email notification
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    emailext (
                        subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                        body: """
                            <p>Build Status: <strong>${currentBuild.currentResult}</strong></p>
                            <p>Check console output at: <a href="${env.BUILD_URL}">${env.JOB_NAME} #${env.BUILD_NUMBER}</a></p>
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