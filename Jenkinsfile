pipeline {
    agent any

    environment {
        WAR_NAME = "myapp.war"
        BUILD_DIR = "target"
        DEPLOY_DIR = "tomcat/webapps"
        BACKUP_DIR = "rollback"
    }

    stages {
        stage('Build WAR') {
            steps {
                echo "Building WAR using Maven"
                sh 'mvn clean package'
            }
        }

        stage('Backup Last WAR') {
            steps {
                script {
                    sh '''
                        mkdir -p ${BACKUP_DIR}
                        if [ -f ${DEPLOY_DIR}/${WAR_NAME} ]; then
                            echo "Backing up current WAR"
                            cp ${DEPLOY_DIR}/${WAR_NAME} ${BACKUP_DIR}/${WAR_NAME}.bak
                        else
                            echo "No WAR to backup"
                        fi
                    '''
                }
            }
        }

        stage('Deploy WAR') {
            steps {
                echo "Deploying WAR to local Tomcat"
                sh '''
                    mkdir -p ${DEPLOY_DIR}
                    cp ${BUILD_DIR}/${WAR_NAME} ${DEPLOY_DIR}/
                    echo "Deployment complete"
                '''
            }
        }

        stage('Restart Tomcat') {
            steps {
                echo "Simulating Tomcat restart"
                sh '''
                    echo "Stopping Tomcat..."
                    sleep 2
                    echo "Starting Tomcat..."
                    sleep 2
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                echo "Running smoke test"
                // Simulate failure for testing rollback
                sh 'exit 1'  // <-- Change to 0 for success
            }
        }
    }

    post {
        failure {
            echo "Deployment failed! Starting rollback..."
            sh '''
                if [ -f ${BACKUP_DIR}/${WAR_NAME}.bak ]; then
                    echo "Restoring backup WAR..."
                    cp ${BACKUP_DIR}/${WAR_NAME}.bak ${DEPLOY_DIR}/${WAR_NAME}
                    echo "Rollback complete. Restarting Tomcat..."
                    sleep 2
                else
                    echo "No backup WAR found. Cannot rollback!"
                fi
            '''
        }
        success {
            echo "Pipeline completed successfully!"
        }
    }
}
