pipeline {

    agent { 
        node {
            label 'VM-agent'
        }
    }

    stages {

        stage('Build') {
            steps {
                echo "Building.."
                sh '''
                sudo chown -R vagrant:vagrant ./agent
                docker compose build
                '''
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
                sh '''
                docker compose down
                docker compose up
                '''
            }
        }
    }
}