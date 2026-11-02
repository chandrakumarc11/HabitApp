pipeline {
    agent any

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"

        AWS_REGION = 'ap-south-2'
        ECR_REPO = 'habitapp'
        ECR_REGISTRY = '079960139717.dkr.ecr.ap-south-2.amazonaws.com'

        SONAR_SERVER = 'SonarQube'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                sh '''
                    echo "===== Java ====="
                    java -version

                    echo "===== Java Compiler ====="
                    javac -version

                    echo "===== Maven ====="
                    mvn -version

                    echo "===== Git ====="
                    git --version

                    echo "===== Docker ====="
                    docker --version

                    echo "===== AWS CLI ====="
                    aws --version
                '''
            }
        }

        stage('Maven Build and Unit Test') {
            steps {
                sh '''
                    mvn clean verify
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    withCredentials([
                        string(
                            credentialsId: 'habitapp-sonar-token',
                            variable: 'SONAR_TOKEN'
                        )
                    ]) {
                        sh '''
                            mvn sonar:sonar \
                              -Dsonar.projectKey=habit-tracker \
                              -Dsonar.projectName="Habit Tracker" \
                              -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Image Versioning') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_URI = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

                    echo "IMAGE_TAG=${IMAGE_TAG}"
                    echo "IMAGE_URI=${IMAGE_URI}"
                }
            }
        }

        stage('Docker Build') {
            steps {
            
