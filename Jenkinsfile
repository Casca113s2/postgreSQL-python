pipeline {

    agent { 
        node {
            label 'build-in'
        }
    }

    stages {

        stage('Extract Git Commit Hash') {
            steps {
                script {
                    sh "echo 'Extracting Git Commit Hash..'"
                    env.GIT_COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "echo 'Building..'"
                    sh "GIT_COMMIT_HASH=${env.GIT_COMMIT_HASH} docker compose build"
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerHub') {
                        sh '''
                            echo "Pushing.."
                            docker compose push
                        '''
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploy....'
                sh "docker compose down"
                sh "GIT_COMMIT_HASH=${env.GIT_COMMIT_HASH} docker compose up -d"
            }
        }
    }
}