pipeline {

    agent { 
        node {
            label 'build-in'
        }
    }

    environment {
        GIT_COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        DEV_REMOTE_SERVER = 'developer@158.247.231.127'
        DEV_APP_URL = 'https://dev-app.cascabase.online'
        TEST_REMOTE_SERVER = 'tester@158.247.202.148'
        TEST_APP_URL = 'https://test-app.cascabase.online'
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

                    # Save the current running image name
                    CURRENT_IMAGE=\$(docker inspect --format='{{.Config.Image}}' phonebook-app 2>/dev/null || echo '')

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

                    # Save the current running image to a file for rollback
                    if [ -n "\$CURRENT_IMAGE" ]; then
                        echo \$CURRENT_IMAGE > ~/previous_image.txt
                    fi
                    
                    # Remove the deployment script
                    rm -- "\$0"
                    """
                    
                    // Upload the script to the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} scp deploy.sh ${DEV_REMOTE_SERVER}:~/deploy.sh'
                    }

                    // Execute the script on the remote server
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh 'sshpass -p ${SSH_PASSWORD} ssh ${DEV_REMOTE_SERVER} "bash ~/deploy.sh"'
                    }

                    // Remove the local deployment script
                    sh 'rm deploy.sh'
                }
            }
        }

        stage('Healthcheck') {
            steps {
                script {
                    catchError(buildResult: 'FAILURE', stageResult: 'UNSTABLE') { 
                        def commitHash = GIT_COMMIT_HASH
                        def version = "phonebook:dev-${GIT_COMMIT_HASH}"
                        def author = sh(script: 'git log -1 --pretty=format:%an', returnStdout: true).trim()
                        def date = new Date().format('yyyy-MM-dd HH:mm:ss')

                        // Perform healthcheck
                        def healthcheckUrl = "${DEV_APP_URL}/healthcheck"
                        
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
                                currentBuild.result = 'SUCCESS'
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

        stage('Manual Deployment to Tester Server') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    input message: 'Deploy to Tester Server?', ok: 'Deploy', submitter: 'admin'

                    // Deployment script for the tester server
                    writeFile file: 'deploy-test.sh', text: """
                    #!/bin/bash
                    IMAGE_TAG=${GIT_COMMIT_HASH}
                    IMAGE_NAME="casca113s2/phonebook:dev-\$IMAGE_TAG"

                    # Save the current running image name
                    CURRENT_IMAGE=\$(docker inspect --format='{{.Config.Image}}' phonebook-app 2>/dev/null || echo '')

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
                    withCredentials([string(credentialsId: 'tester_ssh_password', variable: 'TEST_SSH_PASSWORD')]) {
                        sh 'sshpass -p ${TEST_SSH_PASSWORD} scp deploy-test.sh ${TEST_REMOTE_SERVER}:~/deploy-test.sh'
                    }

                    // Execute the script on the remote server
                    withCredentials([string(credentialsId: 'tester_ssh_password', variable: 'TEST_SSH_PASSWORD')]) {
                        sh 'sshpass -p ${TEST_SSH_PASSWORD} ssh ${TEST_REMOTE_SERVER} "bash ~/deploy-test.sh"'
                    }

                    // Remove the local deployment script
                    sh 'rm deploy-test.sh'

                    // Send deploy to test server information to Discord
                    def testerMessage = """{
                        "embeds": [{
                            "title": "Deployment to Tester Server",
                            "color": 12745742,
                            "fields": [
                                {"name": "Deployed Version", "value": "phonebook:dev-${GIT_COMMIT_HASH}", "inline": true},
                                {"name": "Date", "value": "${new Date().format('yyyy-MM-dd HH:mm:ss')}", "inline": true}
                            ]
                        }]
                    }"""
                    
                    sh """
                        curl -X POST -H "Content-Type: application/json" -d '${testerMessage}' ${DISCORD_WEBHOOK_URL}
                    """
                }
            }
        }

        stage('Rollback') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                script {
                    // Perform rollback
                    withCredentials([string(credentialsId: 'ssh_password', variable: 'SSH_PASSWORD')]) {
                        sh """
                        sshpass -p ${SSH_PASSWORD} ssh ${DEV_REMOTE_SERVER} bash -c '
                        if [ -f ~/previous_image.txt ]; then
                            PREV_IMAGE=\$(cat ~/previous_image.txt)
                            if [ -n "\$PREV_IMAGE" ]; then
                                echo "Rolling back to previous image: \$PREV_IMAGE"
                                docker stop phonebook-app || true
                                docker rm phonebook-app || true
                                docker image rm \$(docker image ls -qa) || true
                                docker pull \$PREV_IMAGE
                                docker run -d \\
                                  --name phonebook-app \\
                                  --network host \\
                                  \$PREV_IMAGE
                            fi
                        fi
                        '
                        """

                        // Retrieve the previous image name from the remote server
                        sh 'sshpass -p ${SSH_PASSWORD} scp ${DEV_REMOTE_SERVER}:~/previous_image.txt previous_image.txt'
                        
                        // Read the previous image name
                        def prevImage = readFile('previous_image.txt').trim()
                        
                        // Save it as an environment variable for later use
                        env.PREV_IMAGE = prevImage

                        // Send rollback information to Discord
                        def rollbackMessage = """{
                            "embeds": [{
                                "title": "Deployment Rollback",
                                "color": 10181046,
                                "fields": [
                                    {"name": "Rolled Back To Version", "value": "${env.PREV_IMAGE}", "inline": true},
                                    {"name": "Date", "value": "${new Date().format('yyyy-MM-dd HH:mm:ss')}", "inline": true}
                                ]
                            }]
                        }"""

                        sh """
                            curl -X POST -H "Content-Type: application/json" -d '${rollbackMessage}' ${DISCORD_WEBHOOK_URL}
                        """
                    }
                }
            }
        }
    }

    post {
        // Clean after build
        always {
            cleanWs()
        }
    }
}
