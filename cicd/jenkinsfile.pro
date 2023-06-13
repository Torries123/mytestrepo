pipeline {
  agent any
  
  environment {
    REGION          = 'ap-southeast-2'
    ImgName         = 'metatree-transfer-agent-uat'
    CntName         = 'metatree-transfer-agent-uat' 
    DockerFile      = 'Dockerfile.pro'
    NODE_ENV        = 'PRODUCTION'
    CONTAINER_PORT  = '3001'
    EXPOSE_PORT     = '23001'
    JWT_SECRET      = 'METATREESECRET'
  }

  options {
    // Keep maximum 10 archievd artifacts
    buildDiscarder(logRotator(numToKeepStr:'10', artifactNumToKeepStr:'10'))
    // No simultaneous builds
    disableConcurrentBuilds()
    durabilityHint('MAX_SURVIVABILITY') // PERFORMANCE_OPTIMIZED or SURVIVABLE_NONATOMIC
    ansiColor('xterm')
  }

  stages {
    stage('stop old service') {
      steps {
        echo 'Stop old service'
        sh '''
          if [ "$(docker ps -q -f name=${CntName})" ]; then
            docker stop $CntName && docker rm $CntName && docker rmi $ImgName
            sleep 5
          fi
          sleep 5
        '''
      }
    }

    stage('Build image') {
      steps {
        echo 'Building metatree-transfer-agent-uat image...'
        sh "docker build -t ${ImgName} -f ${DockerFile} ."
      }
    }

    stage('Restart Service') {
      steps {
        echo 'running metatree-transfer-agent-uat container...'
        sh 'docker run -d -p $EXPOSE_PORT:$CONTAINER_PORT --restart=always --name $CntName -e NODE_ENV=$NODE_ENV -e PORT=$CONTAINER_PORT -e JWT_SECRET=$JWT_SECRET $ImgName'
      }
    }
  }

  post {
    always {
      //clean jenkins workspace
      cleanWs()
    }
    success {
      bitbucketStatusNotify(buildState: 'SUCCESSFUL')
      echo 'Success.'
    }
    failure {
      bitbucketStatusNotify(buildState: 'FAILED')
      echo 'Failure.'
    }
  }
}