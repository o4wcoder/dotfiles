#!/bin/bash 
export GRADLE_HOME=/tmp/gradle/gradle-2.9
PATH=$GRADLE_HOME/bin:$PATH
export PATH
# Turning on the Gradle daemon by default
export GRADLE_OPTS="-Dorg.gradle.daemon=true" >> ~/.bash_profile &&\
source ~/.bash_profile
