@echo off
setlocal enabledelayedexpansion

rem ===== CONFIG =====
set SRC_DIR=%cd%\libuv-src
set BUILD_DIR=%cd%\libuv-build
set INSTALL_DIR=%cd%\libuv-install
rem ===================

rem 1) Clone (shallow)
if not exist "%SRC_DIR%" git clone --depth 1 https://github.com/libuv/libuv "%SRC_DIR%"

rem 2) Configure → VS 2022, Release, static lib, prefix = INSTALL_DIR
cmake -S "%SRC_DIR%" -B "%BUILD_DIR%" ^
 -G "Visual Studio 17 2022" -A x64 ^
 -DBUILD_SHARED_LIBS=OFF ^
 -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%"

rem 3) Build + install
cmake --build "%BUILD_DIR%" --config Release --target install -- /m

echo.
echo DONE – headers em "%INSTALL_DIR%\include", libs em "%INSTALL_DIR%\lib".
echo Adicione ao CMAKE_PREFIX_PATH quando for compilar o PyTorch:
echo    set CMAKE_PREFIX_PATH=%%CMAKE_PREFIX_PATH%%;%INSTALL_DIR%
endlocal