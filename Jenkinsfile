pipeline {
    agent any
    tools {
        jdk 'JDK17'  // Added from comprehensive
        nodejs 'NodeJS16'  // Added from comprehensive
    }
    environment {
        DOCKER_IMAGE = 'younas126/connect-four-deployment'
        K8S_NAMESPACE = 'default'
        SCANNER_HOME = tool 'sonar-scanner'  // Added from comprehensive
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
                        bat 'aws --version || echo "AWS CLI not installed"'
                        bat 'terraform --version || echo "Terraform not installed"'
                        
                        // Check and install Trivy if missing
                        def trivyInstalled = bat(returnStatus: true, script: 'trivy --version || echo "Trivy not found"') == 0
                        if (!trivyInstalled) {
                            echo "Installing Trivy..."
                            bat 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin'
                            bat 'trivy --version'
                            env.SKIP_TRIVY = 'false'
                        } else {
                            env.SKIP_TRIVY = 'false'
                        }
                        
                        // Check Docker Scout
                        bat 'docker-scout --version || echo "Docker Scout not available"'
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

        // Added from comprehensive
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    bat '%SCANNER_HOME%/bin/sonar-scanner -Dsonar.projectName=connect-four -Dsonar.projectKey=connect-four'
                }
            }
        }
        
        // Added from comprehensive
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }

        // Added from comprehensive
        stage('Security Scans') {
            parallel {
                stage('OWASP Scan') {
                    steps {
                        dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                    }
                }
                stage('Trivy FS Scan') {
                    steps {
                        bat 'trivy fs . > trivyfs.txt'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                            bat 'docker build -t %DOCKER_IMAGE%:latest .'
                            // Added from comprehensive
                            bat 'docker tag %DOCKER_IMAGE%:latest %DOCKER_IMAGE%:latest'
                        }
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
                        bat 'trivy image --exit-code 0 --severity HIGH,CRITICAL --format table -o trivy-image-report.html %DOCKER_IMAGE%:latest'
                        // Added from comprehensive
                        bat 'trivy image %DOCKER_IMAGE%:latest > trivyimage.txt'
                        archiveArtifacts artifacts: 'trivy*.html,trivy*.txt', allowEmptyArchive: true
                    } catch (Exception e) {
                        echo "WARNING: Trivy scan failed - ${e.getMessage()}"
                    }
                }
            }
        }

        // Added from comprehensive
        stage('Docker Scout Scan') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        bat 'docker-scout quickview %DOCKER_IMAGE%:latest'
                        bat 'docker-scout cves %DOCKER_IMAGE%:latest'
                        bat 'docker-scout recommendations %DOCKER_IMAGE%:latest'
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

        // Added from comprehensive
        stage('Manual Approval') {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        mail(
                            to: 'younasrazakhan786@gmail.com',
                            subject: "Approval required for ${env.JOB_NAME}",
                            body: "Please approve deployment at: ${env.BUILD_URL}"
                        )
                        input(
                            id: "DeployGate",
                            message: "Approve deployment?",
                            submitter: "approver"
                        )
                    }
                }
            }
        }

        // Added from comprehensive
        stage('Container Cleanup') {
            steps {
                bat 'docker stop connectfour || echo "No container to stop"'
                bat 'docker rm connectfour || echo "No container to remove"'
            }
        }

        // Added from comprehensive
        stage('Run Docker Container') {
            steps {
                bat 'docker run -d --name connectfour -p 5000:80 %DOCKER_IMAGE%:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    try {
                        withKubeConfig([
                            credentialsId: 'k8s-config',
                            serverUrl: ''
                        ]) {
                            bat 'kubectl apply -f manifests/'
                            // Added from comprehensive
                            bat 'kubectl apply -f service.yaml'
                        }
                    } catch (Exception e) {
                        error("Kubernetes deployment failed: ${e.getMessage()}")
                    }
                }
            }
        }

        // Added from comprehensive
        stage('Verify Kubernetes Deployment') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'k8s-config']) {
                        bat 'kubectl get all'
                        bat 'kubectl get pods'
                        bat 'kubectl get svc'
                        bat 'kubectl get ns'
                    }
                }
            }
        }
    }

    post { 
        always {
            script { 
                def bannerColor = currentBuild.currentResult == 'SUCCESS' ? 'green' : 'red'
                
                // Enhanced email from comprehensive
                emailext (
                    attachLog: true,
                    subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                    body: """ 
                        <html> 
                        <body> 
                        <div style="border: 4px solid ${bannerColor}; padding: 10px;"> 
                        <h2>${env.JOB_NAME} - Build ${env.BUILD_NUMBER}</h2> 
                        <div style="background-color: ${bannerColor}; padding: 10px;"> 
                        <h3 style="color: white;">Pipeline Status: ${currentBuild.currentResult}</h3> 
                        </div> 
                        <p>Check the <a href="${env.BUILD_URL}">console output</a>.</p> 
                        </div> 
                        </body> 
                        </html> 
                    """,
                    to: 'younasrazakhan786@gmail.com',
                    from: 'jenkins@example.com',
                    replyTo: 'jenkins@example.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'trivy-image-report.html,trivyfs.txt,trivyimage.txt'
                )
                
                // Cleanup
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    bat 'docker rmi %DOCKER_IMAGE%:latest || echo "Image already removed"'
                    bat 'docker system prune -af || echo "Cleanup failed"'
                }
            }
        }
    }
}