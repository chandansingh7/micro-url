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
                    script {
                        def envFileContent = readFile("${ENV_FILE}").trim()
                        def envLines = envFileContent.split('\n')
                        envLines.each { line ->
                            if (line.trim() && !line.startsWith("#")) {
                                def (key, value) = line.split('=', 2)
                                env[key.trim()] = value.trim().replace("\"", "").replace(";", "") // Remove quotes & semicolon
                            }
                        }
                    }
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

        stage('Set Environment Variables in Azure') {
            steps {
                sh """
                    az functionapp config appsettings set -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --settings \
                        DB_URL="${env.DB_URL}" \
                        DB_USER="${env.DB_USER}" \
                        DB_PASSWORD="${env.DB_PASSWORD}" \
                        DIALECT="${env.DIALECT}" \
                        JWT_SECRET="${env.JWT_SECRET}" \
                        FRONTEND_URL="${env.FRONTEND_URL}"
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
