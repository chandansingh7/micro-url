pipeline {
    agent any

    environment {
        AZURE_CREDENTIALS_ID = 'azure-jenkins-creds'
        FUNCTION_APP_NAME = 'myMicroUrlFunctionApp'
        RESOURCE_GROUP = 'myMicroUrlResourceGroup'
        DEPLOYMENT_PACKAGE = "functionapp.zip"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/chandansingh7/micro-url.git'
            }
        }

        stage('Load Environment Variables from .env') {
                    steps {
                        withCredentials([file(credentialsId: 'env-file-secret', variable: 'ENV_FILE')]) {
                            sh '''#!/bin/bash
                                set -a
                                source "$ENV_FILE"
                                set +a
                            '''
                        }
                    }
                }

        stage('Build with Gradle') {
            steps {
                sh './gradlew clean build -x test'
            }
        }

        stage('Package for Deployment') {
            steps {
                sh '''
                    #!/bin/bash -e
                    mkdir -p deployment
                    cp build/libs/micro-url-0.0.1-SNAPSHOT.jar deployment/
                    cd deployment
                    zip -r ../$DEPLOYMENT_PACKAGE .
                '''
            }
        }

        stage('Set Environment Variables in Azure') {
            steps {
                sh '''
                    #!/bin/bash -e
                    az functionapp config appsettings set -g "$RESOURCE_GROUP" -n "$FUNCTION_APP_NAME" --settings \
                        DB_URL="$DB_URL" \
                        DB_USER="$DB_USER" \
                        DB_PASSWORD="$DB_PASSWORD" \
                        DIALECT="$DIALECT" \
                        JWT_SECRET="$JWT_SECRET" \
                        FRONTEND_URL="$FRONTEND_URL"
                '''
            }
        }

        stage('Deploy to Azure Functions') {
            steps {
                sh '''
                    #!/bin/bash -e
                    az functionapp deployment source config-zip -g "$RESOURCE_GROUP" -n "$FUNCTION_APP_NAME" --src "$DEPLOYMENT_PACKAGE"
                '''
            }
        }
    }
}
