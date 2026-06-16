#!/bin/sh
# ----------------------------------------------------------------------------
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Apache Maven Wrapper startup batch script, version 3.3.2
# ----------------------------------------------------------------------------

# Optional ENV vars
#   MVNW_REPOURL - repo url base for downloading maven distribution
#   MVNW_USERNAME/MVNW_PASSWORD - user and password for downloading maven
#   MVNW_VERBOSE - true: enable verbose log; others: silence the output
# ----------------------------------------------------------------------------

set -euf
[ "${MVNW_VERBOSE-}" = "true" ] && set -v

# find MAVEN_HOME
if [ -z "${MAVEN_HOME-}" ]; then
  # resolve links - $0 may be a softlink
  PRG="$0"
  while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG="`dirname "$PRG"`/$link"
    fi
  done

  # set MAVEN_HOME
  MAVEN_HOME="$HOME/.m2/wrapper/dists/.mvn/wrapper"
fi

wrapperJarPath="$MAVEN_HOME/maven-wrapper.jar"
wrapperUrl="https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/${MVNW_VERSION:-3.3.2}/maven-wrapper-${MVNW_VERSION:-3.3.2}.jar"

if [ -n "${MVNW_REPOURL-}" ]; then
  wrapperUrl="$MVNW_REPOURL/org/apache/maven/wrapper/maven-wrapper/${MVNW_VERSION:-3.3.2}/maven-wrapper-${MVNW_VERSION:-3.3.2}.jar"
fi

# default MAVEN_USER_HOME
if [ -z "${MAVEN_USER_HOME-}" ]; then
  export MAVEN_USER_HOME="${HOME}/.m2"
fi

# Download and install maven-wrapper.jar if needed
if [ ! -f "$wrapperJarPath" ]; then
  if command -v curl > /dev/null 2>&1; then
    if [ -n "${MVNW_USERNAME-}" ] && [ -n "${MVNW_PASSWORD-}" ]; then
      curl -f -L -u "${MVNW_USERNAME}:${MVNW_PASSWORD}" -o "$wrapperJarPath" "$wrapperUrl"
    else
      curl -f -L -o "$wrapperJarPath" "$wrapperUrl"
    fi
  elif command -v wget > /dev/null 2>&1; then
    if [ -n "${MVNW_USERNAME-}" ] && [ -n "${MVNW_PASSWORD-}" ]; then
      wget --http-user="${MVNW_USERNAME}" --http-password="${MVNW_PASSWORD}" -O "$wrapperJarPath" "$wrapperUrl"
    else
      wget -O "$wrapperJarPath" "$wrapperUrl"
    fi
  else
    echo "ERROR: Neither curl nor wget found. Please install one of them." >&2
    exit 1
  fi
fi

# Determine the Java command to use to start the JVM.
if [ -n "${JAVA_HOME-}" ] ; then
  if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
    # IBM's JDK on AIX uses strange locations for the executables
    JAVACMD="$JAVA_HOME/jre/sh/java"
  else
    JAVACMD="$JAVA_HOME/bin/java"
  fi
  if [ ! -x "$JAVACMD" ] ; then
    echo "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME" >&2
    echo "Please set the JAVA_HOME variable in your environment to match the" >&2
    echo "location of your Java installation." >&2
    exit 1
  fi
else
  JAVACMD="java"
  if ! command -v java >/dev/null 2>&1 ; then
    echo "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH." >&2
    echo "Please set the JAVA_HOME variable in your environment to match the" >&2
    echo "location of your Java installation." >&2
    exit 1
  fi
fi

# Increase the maximum file descriptors if we can.
if [ "$(uname)" = "Darwin" ] && [ "$HOME" = "$PWD" ]; then
  echo "WARNING: Running Maven from your home directory can cause problems." >&2
fi

# Collect all arguments for the java command
MAVEN_PROJECTBASEDIR="${MAVEN_BASEDIR:-$(cd "$(dirname "$0")"; pwd)}"
export MAVEN_PROJECTBASEDIR

exec "$JAVACMD" \
  $MAVEN_OPTS \
  -classpath "$wrapperJarPath" \
  "-Dmaven.home=${MAVEN_HOME}" \
  "-Dmaven.multiModuleProjectDirectory=${MAVEN_PROJECTBASEDIR}" \
  ${WRAPPER_LAUNCHER:-org.apache.maven.wrapper.MavenWrapperMain} \
  "$@"
