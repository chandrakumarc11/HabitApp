pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-south-2'
        AWS_ACCOUNT  = '079960139717'
        ECR_REPO     = 'habitapp'
        ECR_REGISTRY = '079960139717.dkr.ecr.ap-south-2.amazonaws.com'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build & Unit Test') {
            steps {
                sh '''
                    java -version
                    mvn -version
                    mvn clean verify
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
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

                    env.IMAGE_URI =
                        "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

                    echo "Image = ${IMAGE_URI}"
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_URI} .
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region ${AWS_REGION} |
                    docker login \
                      --username AWS \
                      --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Push Image') {
            steps {
                sh '''
                    docker push ${IMAGE_URI}
                '''
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

        stage('Commit Deployment Change') {
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

                        if ! git diff --cached --quiet; then
                            git commit -m "Update HabitApp image to ${IMAGE_TAG}"

                            git push \
                              https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/chandrakumarc11/HabitApp.git \
                              HEAD:main
                        else
                            echo "No Helm image change required"
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'HabitApp CI completed successfully.'
            echo 'Argo CD will deploy the Git change.'
        }

        failure {
            echo 'HabitApp CI pipeline failed.'
        }

        always {
            deleteDir()
        }
    }
}
