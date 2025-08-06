pipeline {
    agent any
    environment {
        DEPLOY_USER = credentials('tomcat-ssh-user')
        DEPLOY_HOST = '192.168.1.100'
        REMOTE_TOMCAT = '/opt/tomcat/webapps'
        BACKUP_DIR = '/opt/tomcat/backup'
    }
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-user/myapp-war-sample.git'
            }
        }
        stage('Build WAR') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Deploy to Tomcat') {
            steps {
                script {
                    def warFile = "target/myapp.war"
                    def deploy = '''
                        ssh $DEPLOY_USER@$DEPLOY_HOST '
                            mkdir -p $BACKUP_DIR &&
                            cp $REMOTE_TOMCAT/myapp.war $BACKUP_DIR/myapp.war ||
                            echo "No previous WAR to backup" &&
                            rm -rf $REMOTE_TOMCAT/myapp &&
                            cp -r -f /dev/null $REMOTE_TOMCAT/myapp &&
                            exit 0
                        '
                        scp $warFile $DEPLOY_USER@$DEPLOY_HOST:$REMOTE_TOMCAT/
                        ssh $DEPLOY_USER@$DEPLOY_HOST 'systemctl restart tomcat'
                    '''
                    try {
                        sh deploy
                    } catch (err) {
                        echo 'Deployment failed. Rolling back...'
                        sh "ssh $DEPLOY_USER@$DEPLOY_HOST '$WORKSPACE/rollback.sh'"
                        error("Deployment failed and rollback triggered.")
                    }
                }
            }
        }
        stage('Post-deploy Smoke Test') {
            steps {
                script {
                    def result = sh(script: "curl -s -o /dev/null -w \"%{http_code}\" http://${DEPLOY_HOST}:8080/myapp/", returnStdout: true).trim()
                    if (result != "200") {
                        error("Smoke test failed: Got HTTP $result")
                    } else {
                        echo "Smoke test passed: HTTP $result"
                    }
                }
            }
        }
    }
    post {
        success {
            mail to: 'devops-team@example.com',
                 subject: "✅ Deployment Successful: myapp.war",
                 body: "The deployment to Tomcat was successful."
        }
        failure {
            mail to: 'devops-team@example.com',
                 subject: "❌ Deployment Failed: myapp.war",
                 body: "Deployment or smoke test failed. Rollback attempted."
        }
    }
}
