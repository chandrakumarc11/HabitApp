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
                    java -version
                    javac -version
                    mvn -version
                    git --version
                    docker --version
                    aws --version
                '''
            }
        }

        stage('Maven Build and Unit Test') {
            steps {
                sh 'mvn clean verify'
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
                              -Dsonar.token=$SONAR_TOKEN
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
                sh 'docker build -t ${IMAGE_URI} .'
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region ${AWS_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh 'docker push ${IMAGE_URI}'
            }
        }

        stage('Update Helm Image Tag') {
            steps {
                sh '''
                    sed -i \
                      "s/^  tag: .*/  tag: \\"${IMAGE_TAG}\\"/" \
                      helm/habitapp/values.yaml

                    grep -A3 '^image:' helm/habitapp/values.yaml
                '''
            }
        }

        stage('Commit Helm Change') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-habitapp',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh '''
                        git config user.name "Jenkins"
                        git config user.email "jenkins@habitapp.local"

                        git add helm/habitapp/values.yaml

                        if git diff --cached --quiet; then
                            echo "No Helm image tag change required"
                        else
                            git commit -m "Update HabitApp image to ${IMAGE_TAG}"

                            git push \
                              https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/chandrakumarc11/HabitApp.git \
                              HEAD:main
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'HabitApp CI pipeline SUCCESS'
            echo 'Argo CD will handle deployment'
        }

        failure {
            echo 'HabitApp CI pipeline FAILED'
        }

        always {
            cleanWs()
        }
    }
}
