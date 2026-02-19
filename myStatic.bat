@echo off
@REM ==================================================================
@REM ==               SCRIPT DE BUILD PARA PYTORCH ESTATICO            ==
@REM ==================================================================
@REM == Autor: [Seu Nome]
@REM == Data: [Data de Hoje]
@REM == Objetivo: Criar um ambiente de build limpo e repetível.
@REM ==================================================================

ECHO [INFO] Configurando o ambiente do Visual Studio...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERRO] Falha ao configurar o ambiente do MSVC. Abortando.
    GOTO :EOF
)

ECHO [INFO] Configurando o ambiente do Python...
set "PYTHON_VENV_PATH=C:\pytorch\venv"
call %PYTHON_VENV_PATH%\Scripts\activate.bat
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERRO] Falha ao ativar o virtualenv em %PYTHON_VENV_PATH%. Abortando.
    GOTO :EOF
)

@REM ==================================================================
@REM ==               CONFIGURACOES DE BUILD DO PYTORCH              ==
@REM ==================================================================
ECHO [INFO] Definindo as flags de build do PyTorch...

@REM --- Estrategia de Build e Runtime ---
set CMAKE_PROJECT_INCLUDE=c:/pytorch/tweak_runtime.cmake
set BUILD_SHARED_LIBS=ON
set BUILD_PYTHON=ON
set BUILD_BINARY=OFF
set BUILD_TEST=OFF
set BUILD_LAZY_TS_BACKEND=ON
set CAFFE2_USE_MSVC_STATIC_RUNTIME=OFF

@REM --- Features Principais (CUDA) ---
set USE_CUDA=ON
set USE_NVRTC=ON
set USE_CUDNN=ON
set USE_STATIC_CUDNN=OFF
set USE_FLASH_ATTENTION=ON

@REM --- Features Principais (CPU & Geral) ---
set USE_MIMALLOC=ON
set USE_MIMALLOC_ON_MKL=ON
set MI_BUILD_STATIC=OFF
set MKLProductDir=C:/Program Files (x86)/Intel/oneAPI

@REM --- Features de Otimizacao/Compilador ---
set USE_GOLD_LINKER=OFF
set MSVC_Z7_OVERRIDE=OFF
set USE_NATIVE_ARCH=TRUE

@REM --- Backends e Aceleradores Desativados ---
set USE_MKLDNN=ON
set USE_XNNPACK=OFF
set USE_FBGEMM=OFF
set USE_MAGMA=OFF

@REM --- Plataformas e Ecossistemas Desativados ---
set libuv_ROOT=C:/pytorch/third_party/libuv/libuv-install
set USE_LIBUV_DEFAULT=ON
set USE_DISTRIBUTED=ON
set USE_GLOO=ON
set USE_MPI=OFF
set USE_XPU=OFF
set USE_MPS=OFF
set CAN_COMPILE_METAL=OFF
set USE_COREML_DELEGATE=OFF
set USE_GLOO_WITH_OPENSSL=OFF

@REM --- Ferramentas e Subprojetos Desativados ---
set BUILD_FUNCTORCH=OFF
set BUILD_EXECUTORCH=OFF
set ONNX_BUILD_TESTS=OFF
set USE_LITE_PROTO=OFF
set CMAKE_VERBOSE_MAKEFILE=OFF

@REM --- Profiling e Debug Desativados ---
set USE_ITT=OFF
set USE_KINETO=OFF
set PRINT_CMAKE_DEBUG_INFO=OFF
set USE_SOURCE_DEBUG_ON_MOBILE=OFF

@REM --- Variaveis de Performance ---
set MAX_JOBS=16

@REM --- Arquiteturas CUDA ---
set TORCH_CUDA_ARCH_LIST=8.6
set CMAKE_CUDA_ARCHITECTURES=OFF

ECHO [INFO] Ambiente configurado. Iniciando o build...
ECHO ==================================================================

@@REM --- Comando de execucao ---
pip wheel . -v --no-build-isolation -w dist/

ECHO [INFO] Processo de build finalizado.