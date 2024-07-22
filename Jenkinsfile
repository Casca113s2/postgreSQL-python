pipeline {

    agent { 
        node {
            label 'build-in'
        }
    }

    environment {
        GIT_COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        REMOTE_SERVER = 'developer@158.247.231.127'
        //DEPLOY_SCRIPT_PATH = './deploy.sh'
        SSH_PASSWORD = credentials('ssh_password')
    }

    stages {

        stage('Build Docker Image') {
            steps {
                script {
                    sh "echo 'Building Docker Image...'"
                    sh "GIT_COMMIT_HASH=${env.GIT_COMMIT_HASH} docker compose build"
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
                    IMAGE_NAME="casca113s2/phonebook:\$IMAGE_TAG"

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
                    """
                    
                    // Upload the script to the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} scp deploy.sh ${REMOTE_SERVER}:~/deploy.sh'
                    }

                    // Execute the script on the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} ssh ${REMOTE_SERVER} "bash ~/deploy.sh"'
                    }
                }
            }
        }
    }
}
