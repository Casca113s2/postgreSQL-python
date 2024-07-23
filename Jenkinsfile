pipeline {

    agent { 
        node {
            label 'build-in'
        }
    }

    environment {
        GIT_COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        REMOTE_SERVER = 'developer@158.247.231.127'
        APP_URL = 'https://dev-app.cascabase.online'
        SSH_PASSWORD = credentials('ssh_password')
        DISCORD_WEBHOOK_URL = credentials('Discord-WebHook')
    }

    stages {

        stage('Build Docker Image') {
            steps {
                script {
                    sh "echo 'Building Docker Image...'"
                    sh "GIT_COMMIT_HASH=${GIT_COMMIT_HASH} docker compose build"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerHub') {
                        sh '''
                            echo "Pushing Docker Image to Docker Hub..."
                            docker compose push
                        '''
                    }
                }
            }
        }

        stage('Deploy Docker Image') {
            steps {
                script {
                    // Create a temporary local file to store the deployment script
                    writeFile file: 'deploy.sh', text: """
                    #!/bin/bash
                    IMAGE_TAG=${GIT_COMMIT_HASH}
                    IMAGE_NAME="casca113s2/phonebook:dev-\$IMAGE_TAG"

                    # Stop and remove the existing container (if any)
                    docker stop phonebook-app || true
                    docker rm phonebook-app || true

                    # Delete all the previous image (if exist)
                    docker image rm \$(docker image ls -qa) || true

                    # Pull the latest Docker image
                    docker pull \$IMAGE_NAME
                    
                    # Run the new Docker image
                    docker run -d \\
                      --name phonebook-app \\
                      --network host \\
                      \$IMAGE_NAME
                    # Remove the deployment script
                    rm -- "\$0"
                    """
                    
                    // Upload the script to the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} scp deploy.sh ${REMOTE_SERVER}:~/deploy.sh'
                    }

                    // Execute the script on the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} ssh ${REMOTE_SERVER} "bash ~/deploy.sh"'
                    }

                    // Remove the local deployment script
                    sh 'rm deploy.sh'
                }
            }
        }

        stage('Healthcheck') {
            steps {
                script {
                    def commitHash = GIT_COMMIT_HASH
                    def version = "phonebook:dev-${GIT_COMMIT_HASH}"
                    def author = sh(script: 'git log -1 --pretty=format:%an', returnStdout: true).trim()
                    def date = new Date().format('yyyy-MM-dd HH:mm:ss')

                    // Perform healthcheck
                    def healthcheckUrl = "${APP_URL}/healthcheck"
                    
                    for(int i=0; i<10; i++) {
                        sh "sleep 10"
                        def healthcheckResponse = sh(script: "curl -v -s -o /dev/null -w '%{http_code}' ${healthcheckUrl}", returnStdout: true).trim()
                        
                        if (healthcheckResponse == '200') {
                            echo "Healthcheck passed: Server is online."
                            //Test success
                            date = new Date().format('yyyy-MM-dd HH:mm:ss')
                            
                            def message = """{
                                "embeds": [{
                                    "title": "Build Status: Success",
                                    "color": 3066993,
                                    "fields": [
                                        {"name": "Deployed Version", "value": "${version}", "inline": true},
                                        {"name": "Date", "value": "${date}", "inline": true},
                                        {"name": "Author", "value": "${author}", "inline": true},
                                        {"name": "Commit Hash", "value": "${commitHash}", "inline": false}
                                    ]
                                }]
                            }"""
                            
                            sh """
                                curl -X POST -H "Content-Type: application/json" -d '${message}' ${DISCORD_WEBHOOK_URL}
                            """
                            return;
                        }
                    }

                    //Test fail
                    date = new Date().format('yyyy-MM-dd HH:mm:ss')
                    
                    def message = """{
                        "embeds": [{
                            "title": "Build Status: Failure",
                            "color": 15158332,
                            "fields": [
                                {"name": "Deployed Version", "value": "${version}", "inline": true},
                                {"name": "Date", "value": "${date}", "inline": true},
                                {"name": "Author", "value": "${author}", "inline": true},
                                {"name": "Commit Hash", "value": "${commitHash}", "inline": false}
                            ]
                        }]
                    }"""

                    sh """
                        curl -X POST -H "Content-Type: application/json" -d '${message}' ${DISCORD_WEBHOOK_URL}
                    """
                    error("Healthcheck failed: Server is not responding with status 200.")
                }
            }
        }
    }
}
