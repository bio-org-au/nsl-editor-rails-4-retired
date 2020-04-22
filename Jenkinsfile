pipeline {
    agent {
        docker { image 'jruby:9.1.17-jdk' }
    }
    options {
        skipStagesAfterUnstable()
    }
    stages {
        stage('Test'){
            steps {
                sh 'env'
            }
        }
    }
}
