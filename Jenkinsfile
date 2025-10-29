pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select deployment environment')
    }

    environment {
        IMAGE_NAME = "springboot-app"
        APP_PORT = "8085" // internal app port
    }

    stages {
        stage('Initialize Environment Variables') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        env.CONTAINER_NAME = "team2-springboot-prod"
                        env.HOST_PORT = "8086"
                        env.DB_HOST = "team_2_prod_postgres"
                        env.DB_NAME = "team_2_prod_db"
                        env.DB_PORT = "5443"
                        CRED_ID = "team2_prod_credentials"
                    } else {
                        env.CONTAINER_NAME = "team2-springboot-dev"
                        env.HOST_PORT = "8082"
                        env.DB_HOST = "team_2_dev_postgres"
                        env.DB_NAME = "team_2_db"
                        env.DB_PORT = "5433"
                        CRED_ID = "team2_dev_credentials"
                    }

                    env.DB_URL = "jdbc:postgresql://${env.DB_HOST}:${env.DB_PORT}/${env.DB_NAME}"

                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Container: ${env.CONTAINER_NAME}"
                    echo "Database: ${env.DB_URL}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                echo "Checking out code..."
                git branch: 'main', url: 'https://github.com/vking6007/team2project.git'
            }
        }

        stage('Build JAR') {
            steps {
                echo "Building Spring Boot JAR..."
                sh 'mvn -version'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT} ."
            }
        }

        stage('Stop Previous Container') {
            steps {
                echo "Stopping old container..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run New Container') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: CRED_ID,
                                                      usernameVariable: 'DB_USER',
                                                      passwordVariable: 'DB_PASS')]) {

                        echo "Deploying new ${params.ENVIRONMENT} container..."

                        sh """
                            # Free port if used
                            if docker ps --format '{{.Ports}}' | grep -q ':${HOST_PORT}->'; then
                              echo 'Port ${HOST_PORT} in use. Stopping...'
                              docker ps --format '{{.ID}} {{.Ports}}' | grep ':${HOST_PORT}->' | awk '{print $1}' | xargs -r docker stop
                            fi

                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              --network jenkins-net \
                              -p ${HOST_PORT}:${APP_PORT} \
                              -e SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT} \
                              -e SPRING_DATASOURCE_URL=${DB_URL} \
                              -e SPRING_DATASOURCE_USERNAME=$DB_USER \
                              -e SPRING_DATASOURCE_PASSWORD=$DB_PASS \
                              -e SERVER_PORT=${APP_PORT} \
                              ${IMAGE_NAME}:${params.ENVIRONMENT}
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "Waiting for app startup..."
                sh 'sleep 20'

                echo "Checking container health..."
                sh """
                    docker ps | grep ${CONTAINER_NAME} || (echo 'Container not running!' && exit 1)
                    docker exec ${CONTAINER_NAME} curl -fsS http://localhost:${APP_PORT}/actuator/health \
                    || (echo 'Health check failed!' && exit 1)
                """
            }
        }
    }

    post {
        success {
            echo "${params.ENVIRONMENT.toUpperCase()} Deployment Successful!"
            echo "App running at: http://localhost:${HOST_PORT}"
        }
        failure {
            echo "${params.ENVIRONMENT.toUpperCase()} Deployment Failed!"
            sh 'docker logs ${CONTAINER_NAME} || true'
        }
        always {
            echo "✅ Jenkins Pipeline finished for ${params.ENVIRONMENT.toUpperCase()}."
        }
    }
}
