# myapp-war-sample
myapp-war-sample

this jenkins file is for remote 

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





This is for local deployment from jenkins to Tomcat code 

pipeline {
    agent any

    environment {
        DEPLOY_DIR = 'C:\\Tomcat\\webapps\\myapp.war'
        BACKUP_DIR = 'C:\\Tomcat\\rollback'
        WORKSPACE = "${env.WORKSPACE}"
        WAR_FILE = "${env.WORKSPACE}\\target\\myapp.war"
        SMTP_FAILURE_EMAIL = 'admin@example.com' // Replace with your actual email
    }

    stages {
        stage('Build WAR') {
            steps {
                echo "Building WAR file..."
                bat 'mvn clean package'
            }
        }

        stage('Backup Existing WAR') {
            steps {
                echo "Backing up current deployed WAR..."
                bat """
                if exist "${DEPLOY_DIR}" (
                    if not exist "${BACKUP_DIR}" mkdir "${BACKUP_DIR}"
                    copy /Y "${DEPLOY_DIR}" "${BACKUP_DIR}\\myapp_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.war"
                )
                """
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo "Deploying WAR to Tomcat..."
                bat """
                copy /Y "${WAR_FILE}" "${DEPLOY_DIR}"
                net stop Tomcat9
                net start Tomcat9
                """
            }
        }

        stage('Smoke Test') {
            steps {
                echo "Running smoke test..."
                sleep time: 10, unit: 'SECONDS'
                script {
                    def rawOutput = bat(
                        script: 'powershell -Command "(Invoke-WebRequest http://localhost:9090/myapp/ -UseBasicParsing).StatusCode"',
                        returnStdout: true
                    )
                    def lines = rawOutput.readLines()
                    def statusCode = lines.last().trim()
                    echo "Smoke test returned status code: ${statusCode}"
                    if (statusCode != "200") {
                        error("Smoke test failed! Status code: ${statusCode}")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment succeeded!"
            // Optional: notify on success
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job SUCCESS: ${env.JOB_NAME}",
            //      body: "The deployment was successful."
        }

        failure {
            echo "❌ Deployment failed. Rolling back..."

            bat """
            setlocal ENABLEDELAYEDEXPANSION
            set "ROLLBACK_FILE="
            for /f %%F in ('dir /b /o-d "${BACKUP_DIR}\\myapp_*.war"') do (
                set "ROLLBACK_FILE=%%F"
                goto done
            )
            :done
            if defined ROLLBACK_FILE (
                copy /Y "${BACKUP_DIR}\\!ROLLBACK_FILE!" "${DEPLOY_DIR}"
                net stop Tomcat9
                net start Tomcat9
            )
            """

            // Optional: notify on failure
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job FAILED: ${env.JOB_NAME}",
            //      body: "The deployment failed and rollback was triggered."
        }
    }
}
