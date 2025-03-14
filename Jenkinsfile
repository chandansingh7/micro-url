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
                        while IFS= read -r line; do
                            [[ -z "$line" || "$line" == \#* ]] && continue
                            key=$(echo "$line" | cut -d= -f1)
                            value=$(echo "$line" | cut -d= -f2-)
                            export "$key=\"$value\""
                        done < "$ENV_FILE"
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
                sh """
                    mkdir -p deployment
                    cp build/libs/micro-url-0.0.1-SNAPSHOT.jar deployment/
                    cd deployment
                    zip -r ../$DEPLOYMENT_PACKAGE .
                """
            }
        }

        stage('Ensure Function App Exists in Azure') {
            steps {
                script {
                    def exists = sh(script: "az functionapp show -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --query 'name' -o tsv || echo 'notfound'", returnStdout: true).trim()
                    if (exists == 'notfound') {
                        error("Azure Function App '$FUNCTION_APP_NAME' does not exist in resource group '$RESOURCE_GROUP'. Deploy it first!")
                    }
                }
            }
        }

        stage('Set Environment Variables in Azure') {
            steps {
                sh """
                    az functionapp config appsettings set -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --settings \
                        DB_URL="$DB_URL" \
                        DB_USER="$DB_USER" \
                        DB_PASSWORD="$DB_PASSWORD" \
                        DIALECT="$DIALECT" \
                        JWT_SECRET="$JWT_SECRET" \
                        FRONTEND_URL="$FRONTEND_URL"
                """
            }
        }

        stage('Deploy to Azure Functions') {
            steps {
                sh """
                    az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --src $DEPLOYMENT_PACKAGE
                """
            }
        }
    }
}
