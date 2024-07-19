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
                docker compose build
                '''
            }
        }
        stage('Push') {
            steps {
                echo "Pushing.."
                script {
                     withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'password', usernameVariable: 'username')]){
                         sh '''
                            echo "${password} | docker login -u ${username} --password-stdin"
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