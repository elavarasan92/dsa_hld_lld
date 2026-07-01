pipeline {
  agent any
  stages {
    stage('Build') { steps { sh 'mvn -B clean package' } }
    stage('Test')  { steps { sh 'mvn test' } }
    stage('Sonar') { steps { sh 'mvn sonar:sonar' } }
    stage('Docker'){ steps { sh 'docker build -t app:$BUILD_NUMBER .' } }
    stage('Deploy'){ steps { sh 'kubectl set image deploy/app app=app:$BUILD_NUMBER' } }
  }
  post { failure { mail to:'team@hl.com', subject:"Build failed" } }
}