pipeline {
    agent any

    environment {
        DEPLOY_USER = credentials('tomcat-ssh-user')     // SSH Username + Password or SSH Key in Jenkins Credentials
        DEPLOY_HOST = '192.168.1.100'
        REMOTE_TOMCAT = '/opt/tomcat/webapps'
        BACKUP_DIR = '/opt/tomcat/backup'
        WAR_FILE = 'target\\myapp.war'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-token', url: 'https://github.com/korupon/myapp-war-sample.git'
            }
        }

        stage('Build WAR') {
            steps {
                bat 'mvn clean package'
            }
        }

        stage('Deploy to Remote Linux Tomcat') {
            steps {
                script {
                    def deployScript = """
                        ssh %DEPLOY_USER%@%DEPLOY_HOST% "
                            mkdir -p %BACKUP_DIR% &&
                            if [ -f %REMOTE_TOMCAT%/myapp.war ]; then
                                cp %REMOTE_TOMCAT%/myapp.war %BACKUP_DIR%/myapp_\$(date +%F_%T).war;
                            fi &&
                            rm -rf %REMOTE_TOMCAT%/myapp
                        "
                        scp %WAR_FILE% %DEPLOY_USER%@%DEPLOY_HOST%:%REMOTE_TOMCAT%/myapp.war
                        ssh %DEPLOY_USER%@%DEPLOY_HOST% "systemctl restart tomcat"
                    """
                    bat label: 'Deploy WAR via SSH', script: deployScript
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    def response = bat(script: "curl -s -o nul -w \"%%{http_code}\" http://%DEPLOY_HOST%:8080/myapp/", returnStdout: true).trim()
                    if (response != "200") {
                        error "Smoke test failed with HTTP $response"
                    } else {
                        echo "✅ Smoke test passed: HTTP $response"
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                to: 'devops-team@example.com',
                subject: "✅ Deployment Successful: myapp.war",
                body: "The deployment to Tomcat at ${DEPLOY_HOST} was successful."
            )
        }
        failure {
            script {
                echo 'Deployment failed. Attempting rollback...'
                bat "ssh %DEPLOY_USER%@%DEPLOY_HOST% '~/rollback.sh'"
            }
            emailext(
                to: 'devops-team@example.com',
                subject: "❌ Deployment Failed: myapp.war",
                body: "Deployment or smoke test failed. Rollback attempted on ${DEPLOY_HOST}."
            )
        }
    }
}
