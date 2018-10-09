pipeline {
    agent {
        label "golang"
    }
    environment {
      PROJECT = 'project-k'
      FOLDER = 'src/github.com/danielfbm/golang-http'
      GOPATH = "${WORKSPACE}"
      DEV_REPOSITORY = 'harbor.harbor-default.k8s-prod.mathilde.com.cn/project-k/go-http-dev'
      IMAGE_REPOSITORY = 'harbor.harbor-default.k8s-prod.mathilde.com.cn/project-k/go-http'
      CREDENTIALS = 'project-k-harbor'
      APP = 'golang-http'
    }
    stages {
      stage('Checkout') {
        steps {
          script {
            dir(env.FOLDER) {
              def scmVar = checkout scm
              env.TAG = "build-${BUILD_ID}"
            }
          }
        }
      }
      stage('CI') {
        failFast true
        parallel {
          stage('Unit Tests') {
            steps {
              dir(FOLDER) {
                container('golang') {
                  sh "go test -cover -v -json > test.json"
                  sh "go test -v -coverprofile=coverage.out -covermode=count ."
                }
              }
            }
          }
          stage('Code Scan') {
            steps {
              dir(FOLDER) {
                container('tools') {
                  withSonarQubeEnv('sonarqube') {
                    sh "sonar-scanner"
                  }
                }
              }
            }
          }
          stage('Build') {
            environment {
              CGO_ENABLED = "0"
              GOOS = "linux"
              GOARCH = "amd64"
            }
            steps {
              dir(FOLDER) {
                container('golang') {
                  sh "go build -v -o bin/golang-http"
                  sh "chmod +x bin/golang-http"
                }
                container('tools') {
                  sh "docker build -t ${IMAGE_REPOSITORY}:${TAG} ."
                  withCredentials([usernamePassword(credentialsId: CREDENTIALS, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    sh "docker login ${IMAGE_REPOSITORY} -u ${USERNAME} -p ${PASSWORD}"
                  }
                  sh "docker push ${IMAGE_REPOSITORY}:${TAG}"
                }
              }
            }
          }
        }
      }
      stage('Deploy') {
        steps {
          script {
            container('tools'){
                timeout(time:300, unit: "SECONDS"){
                    alaudaDevops.withProject(env.PROJECT) {
                        def p = alaudaDevops.selector('deploy', env.APP).object()
                        p.metadata.labels['BUILD_ID']=env.BUILD_ID
                        p.spec.template.spec.containers[0]['image'] = "${IMAGE_REPOSITORY}:${TAG}"
                        alaudaDevops.apply(p)
                    }
                }
            }
          }
        }
      }
      stage('Testing') {
        steps {
          sleep 10
          container('tools'){
            sh "curl --fail http://golang-http.project-k:8080 -v"
          }
        }
      }
      stage('Promoting') {
        steps {
          container('tools') {
            sh "docker tag ${IMAGE_REPOSITORY}:${TAG} ${IMAGE_REPOSITORY}:release"
            withCredentials([usernamePassword(credentialsId: CREDENTIALS, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
              sh "docker login ${IMAGE_REPOSITORY} -u ${USERNAME} -p ${PASSWORD}"
            }
            sh "docker push ${IMAGE_REPOSITORY}:release"
          }
        }
      }
    }
  }
