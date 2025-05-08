pipeline {
    agent any
    tools {
        jdk 'JDK17'
        nodejs 'NodeJS16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh 'jenkins --version'
                sh 'aws --version'
                sh 'kubectl version --client'
                sh 'terraform --version'
                sh 'trivy --version'
                sh 'docker --version'
            }
        }
        
        stage('Checkout from Git') {                        
            steps {                                       
                git branch: 'main', url: 'https://github.com/MYounas126/Connect-Four-Deployment.git'
            }
        }
        
        stage('Deployments') {
            parallel {
                stage('Test deploy to staging') {
                    steps {
                        echo 'staging deployment done'
                    }
                }
                stage('Test deploy to production') {
                    steps {
                        echo 'production deployment done'
                    }
                }
            }
        }
        
        stage('Test Build') {
            steps {
                echo 'Building....'
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to Staging from main....'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to Production from main....'
            }
        }
        
        stage("Sonarqube Analysis") {                         
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=gaming-application \
                    -Dsonar.projectKey=gaming-application'''
                }
            }
        }
        
        stage("quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        
        stage('OWASP File System SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        stage('TRIVY File System SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        
        stage('Docker Scout Image Overview') {
            steps {
                script {
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                       sh 'docker-scout quickview fs://.'
                   }
                }   
            }
        }
        
        stage('Docker Scout CVES File System Scan') {
            steps {
                script {
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                       sh 'docker-scout cves fs://.'
                   }
                }   
            }
        }
        
        stage("Docker Image Building") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {   
                        sh "docker build -t connectfour ." 
                    }
                }
            }
        }
        
        stage("Docker Image Tagging") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker tag connectfour yash5090/connectfour:latest" 
                    }
                }
            }
        }
        
        stage('Docker Image Scanning') { 
            steps { 
                sh "trivy image --format table -o trivy-image-report.html yash5090/connectfour:latest" 
            } 
        } 
        
        stage("Image Push to DockerHub") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker push yash5090/connectfour:latest"
                    }
                }
            }
        }
        
        stage('Docker Scout Image Scanning') {
            steps {
                script {
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                       sh 'docker-scout quickview yash5090/connectfour:latest'
                       sh 'docker-scout cves yash5090/connectfour:latest'
                       sh 'docker-scout recommendations yash5090/connectfour:latest'
                       sh 'docker-scout attestation yash5090/connectfour:latest'
                   }
                }   
            }
        }
        
        stage("TRIVY") {
            steps {
                sh "trivy image yash5090/connectfour:latest > trivyimage.txt"   
            }
        }
        
        stage('Manual Approval') {
          steps {
           script {
             timeout(time: 10, unit: 'MINUTES') {
              approvalMailContent = """
              Project: ${env.JOB_NAME}
              Build Number: ${env.BUILD_NUMBER}
              Go to build URL and approve the deployment request.
              URL de build: ${env.BUILD_URL}
              """
              emailext (
                to: 'younasrazakhan786@gmail.com',
                subject: "Approval Required: ${env.JOB_NAME} - Build ${env.BUILD_NUMBER}", 
                body: approvalMailContent,
                mimeType: 'text/plain'
              )
              input(
                id: "DeployGate",
                message: "Deploy to production?",
                submitter: "approver",
                parameters: [choice(name: 'action', choices: ['Approve', 'Reject'], description: 'Approve or reject deployment')]
              )  
             }
           }
          }
        }

        stage("Remove Docker Container") {
            steps {
                sh "docker stop connectfour || true"
                sh "docker rm connectfour || true"
             }
        }
        
        stage('Deploy to Docker Container') {
            steps {
                sh 'docker run -d --name connectfour -p 5000:80 yash5090/connectfour:latest' 
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                        sh 'kubectl apply -f deployment.yaml'
                        sh 'kubectl apply -f service.yaml'
                    }
                }
            }
        }
        
        stage('Verify the Kubernetes Deployments') { 
            steps { 
                withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') { 
                    sh "kubectl get all" 
                    sh "kubectl get pods" 
                    sh "kubectl get svc"
                    sh "kubectl get ns"
                } 
            } 
        } 
        
        stage('Deployment Done') {
            steps {
                echo 'Deployed Successfully...'
            }
        }
    }
    
    post { 
        always {
            script { 
                def jobName = env.JOB_NAME 
                def buildNumber = env.BUILD_NUMBER 
                def pipelineStatus = currentBuild.result ?: 'SUCCESS' 
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red' 
                def body = """ 
                <html> 
                <body> 
                <div style="border: 4px solid ${bannerColor}; padding: 10px;"> 
                <h2>${jobName} - Build ${buildNumber}</h2> 
                <div style="background-color: ${bannerColor}; padding: 10px;"> 
                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3> 
                </div> 
                <p>Check the <a href="${BUILD_URL}">console output</a>.</p> 
                </div> 
                </body> 
                </html> 
                """ 

                emailext (
                    attachLog: true,
                    subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}", 
                    body: body, 
                    to: 'younasrazakhan786@gmail.com', 
                    from: 'jenkins@example.com', 
                    replyTo: 'jenkins@example.com', 
                    mimeType: 'text/html', 
                    attachmentsPattern: 'trivy-image-report.html, trivyfs.txt, trivyimage.txt'
                ) 
            } 
        } 
    }
}