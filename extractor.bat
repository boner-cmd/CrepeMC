@ECHO OFF
pushd %~dp0
pushd .\builder
If %errorlevel% NEQ 0 goto:eof
@ECHO ON
docker build -t bone4cmdr/crepemc:builder .
docker run --name buildercon bone4cmdr/crepemc:builder
docker cp buildercon:/working/template .\output\Dockerfile
@ECHO OFF
docker stop buildercon >nul
docker rm buildercon >nul
@ECHO ON
popd
copy .\builder\output\Dockerfile
@ECHO OFF
If %errorlevel% NEQ 0 goto:eof
setlocal
set jdk_version_=14
set /p jdk_version_=Use which JDK version? :
@ECHO ON
docker build --build-arg JLINK_JDK_VERSION=%jdk_version_% -t ethco/crepemc:jdk%jdk_version_% .
docker push ethco/crepemc:jdk%jdk_version_%
PAUSE
