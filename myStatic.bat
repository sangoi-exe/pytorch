@echo off
REM ==================================================================
REM ==               SCRIPT DE BUILD PARA PYTORCH ESTATICO            ==
REM ==================================================================
REM == Autor: [Seu Nome]
REM == Data: [Data de Hoje]
REM == Objetivo: Criar um ambiente de build limpo e repetível.
REM ==================================================================

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

REM ==================================================================
REM ==               CONFIGURACOES DE BUILD DO PYTORCH              ==
REM ==================================================================
ECHO [INFO] Definindo as flags de build do PyTorch...

REM --- Estrategia de Build e Runtime ---
set CMAKE_PROJECT_INCLUDE=c:\pytorch\tweak_runtime.cmake
set BUILD_SHARED_LIBS=1
set BUILD_TEST=0
set BUILD_BINARY=0
set CAFFE2_USE_MSVC_STATIC_RUNTIME=0

REM --- Features Principais (CUDA) ---
set USE_CUDA=1
set USE_NVRTC=1
set USE_CUDNN=1
set USE_STATIC_CUDNN=0
set USE_CUDSS=1
set USE_FLASH_ATTENTION=1

REM --- Features Principais (CPU & Geral) ---
set USE_LAPACK=1
set USE_MIMALLOC=1
set MI_BUILD_STATIC=0
set BUILD_CUSTOM_PROTOBUF=0
set USE_PER_OPERATOR_HEADERS=1
set MKLProductDir=C:\Program Files (x86)\Intel\oneAPI

REM --- Features de Otimizacao/Compilador (A maioria irrelevante agora) ---
set USE_GOLD_LINKER=0
set MSVC_Z7_OVERRIDE=0
set USE_NATIVE_ARCH=0

REM --- Backends e Aceleradores Desativados ---
set USE_MKLDNN=0
set USE_XNNPACK=0
set USE_FBGEMM=0
set USE_PTHREADPOOL=0
set USE_MAGMA=0

REM --- Plataformas e Ecossistemas Desativados ---
set libuv_ROOT=C:\pytorch\libuv-install
set USE_DISTRIBUTED=1
set USE_GLOO=1
set USE_LIBUV=1
set USE_MPI=0
set USE_XPU=0
set USE_MPS=0
set CAN_COMPILE_METAL=0
set USE_COREML_DELEGATE=0
set USE_GLOO_WITH_OPENSSL=0

REM --- Ferramentas e Subprojetos Desativados ---
set BUILD_FUNCTORCH=0
set BUILD_EXECUTORCH=0
set ONNX_BUILD_TESTS=0
set USE_LITE_PROTO=0
set CMAKE_VERBOSE_MAKEFILE=0

REM --- Profiling e Debug Desativados ---
set USE_ITT=0
set USE_KINETO=0
set PRINT_CMAKE_DEBUG_INFO=0
set USE_SOURCE_DEBUG_ON_MOBILE=0

REM --- Variaveis de Performance ---
set MAX_JOBS=16

REM --- Arquiteturas CUDA ---
set TORCH_CUDA_ARCH_LIST=8.6

ECHO [INFO] Ambiente configurado. Iniciando o build...
ECHO ==================================================================

REM --- Comando de execucao ---
python setup.py develop

ECHO [INFO] Processo de build finalizado.