 pipeline {
  agent {
     kubernetes {
      defaultContainer 'swym-jdk'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: swym-jdk
spec:
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
  containers:
  - name: swym-jdk
    image: XXXXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/jenkins-slave
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "2Gi"
    volumeMounts:
     - name: docker-sock
       mountPath: /var/run/docker.sock
"""
    }
}

//Provide the correct variables below
environment {
  AWS_REGION = 'us-eat-1'
  PROD_ECR_URL = 'XXXXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/helloworld'
  DEV_EKS_CLUSTER_NAME = 'dev-eks-cluster'
  PROD_EKS_CLUSTER_NAME = 'prod-eks-cluster'
}

triggers {
  pollSCM('H/2 * * * *')
}

options {
  buildDiscarder(logRotator(numToKeepStr: '10'))
  skipStagesAfterUnstable()
  durabilityHint('PERFORMANCE_OPTIMIZED')
  disableConcurrentBuilds()
  skipDefaultCheckout(true)
  overrideIndexTriggers(false)
}

stages {
  stage ('Checkout'){
    steps {
      checkout scm
      script {
        env.commit_id = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        sh(script: "aws ecr get-login --no-include-email --registry-ids --region ${AWS_REGION} | sh", returnStdout: true).trim()
      }
    }
  }

  stage('Maven Build') {
    steps {
      sh './mvnw clean package'
    }
  }

  stage('Docker Build') {
    steps {
      script {
        docker.build('helloworld', '--pull .')
        docker.withRegistry('https://${ECR_URL}') {
          docker.image('helloworld').push(commit_id)
        }
      }
    }
  }

  stage ('Dev Deployment') {
    when {
      beforeAgent true
      branch "master"
    }
    steps {
      sh 'aws eks --region us-east-1 update-kubeconfig --name ${DEV_EKS_CLUSTER_NAME} || exit 1'
      sh '''
      helm upgrade --install helloworld --namespace dev \
      --set-string image.tag=${commit_id} \
      -f ./helm/values-dev.yaml \
      --timeout 600s \
      --wait \
      ./helm || exit 1
      '''
    }
  }

  stage ('Checking Dev Healthcheck') {
    steps {
      sh 'curl dev.helloworld.com -k -s -f -o /dev/null  || exit 1'
    }
    post {
      failure {
        script{
            error "DEV healthcheck failed, exiting now..."
        }
      }
    }
  }

  stage ('PROD Deployment') {
    when {
      beforeAgent true
      branch "master"
    }
    steps {
      timeout ( time: 1, unit: "HOURS" )  {
        input 'Do you want to proceed for production deployment?'
      }
      script {
        sh(script: "aws ecr get-login --no-include-email --registry-ids --region ${AWS_REGION} | sh", returnStdout: true).trim()
      }
      sh 'aws eks --region us-east-1 update-kubeconfig --name ${PROD_EKS_CLUSTER_NAME} || exit 1'
      sh '''
      helm3 upgrade --install helloworld --namespace prod \
      --set-string image.tag=${commit_id} \
      -f ./helm/values-prod.yaml \
      --timeout 600s \
      --wait \
      ./helm || exit 1
      '''
    }
    post {
      success {
        script {
          docker.withRegistry('https://${ECR_URL}') {
            docker.image('helloworld').push("stable")
          }
        }
      }
      failure {
        sh '''
        helm3 upgrade helloworld --namespace prod \
        --reuse-values \
        --set-string image.tag=stable \
        --timeout 600s \
        --wait \
        ./helm || exit 1'
        '''
      }
    }
  }

 }
}
