@echo off
setlocal
@REM ==================================================================
@REM ==               SCRIPT DE BUILD PARA PYTORCH ESTATICO            ==
@REM ==================================================================
@REM == Autor: [Seu Nome]
@REM == Data: [Data de Hoje]
@REM == Objetivo: Criar um ambiente de build limpo e repetível.
@REM ==================================================================

ECHO [INFO] Configurando o ambiente do Visual Studio...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao configurar o ambiente do MSVC. Abortando.
    GOTO :FAIL
)

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao acessar o diretorio do script: %SCRIPT_DIR%
    GOTO :FAIL
)

call :ENSURE_SUBMODULES_READY
IF ERRORLEVEL 1 (
    GOTO :FAIL
)

ECHO [INFO] Configurando o ambiente do Python...
set "LOCAL_VENV_PATH=%SCRIPT_DIR%.venv"
set "ACTIVATE_BAT=%LOCAL_VENV_PATH%\Scripts\activate.bat"
set "PYTHON_EXE=%LOCAL_VENV_PATH%\Scripts\python.exe"
set "BOOTSTRAP_PYTHON=C:\Users\lucas\OneDrive\Documentos\stable-diffusion-webui-codex\.venv\Scripts\python.exe"
set "EXPECTED_PYTHON_VERSION=3.12.10"

IF NOT EXIST "%BOOTSTRAP_PYTHON%" (
    ECHO [ERRO] Python bootstrap nao encontrado em %BOOTSTRAP_PYTHON%.
    ECHO [ERRO] Ajuste BOOTSTRAP_PYTHON no myStatic.bat para um Python %EXPECTED_PYTHON_VERSION%.
    GOTO :FAIL
)

set "BOOTSTRAP_PYTHON_VERSION="
for /f "tokens=2 delims= " %%V in ('"%BOOTSTRAP_PYTHON%" -V 2^>^&1') do set "BOOTSTRAP_PYTHON_VERSION=%%V"
IF NOT DEFINED BOOTSTRAP_PYTHON_VERSION (
    ECHO [ERRO] Nao foi possivel detectar a versao do Python bootstrap em %BOOTSTRAP_PYTHON%.
    GOTO :FAIL
)
IF /I NOT "%BOOTSTRAP_PYTHON_VERSION%"=="%EXPECTED_PYTHON_VERSION%" (
    ECHO [ERRO] Python de bootstrap invalido: encontrado %BOOTSTRAP_PYTHON_VERSION%, esperado %EXPECTED_PYTHON_VERSION%.
    ECHO [ERRO] Ajuste BOOTSTRAP_PYTHON para um Python %EXPECTED_PYTHON_VERSION% e tente novamente.
    GOTO :FAIL
)

IF NOT EXIST "%PYTHON_EXE%" (
    ECHO [INFO] Virtualenv local nao encontrado em %LOCAL_VENV_PATH%. Criando...
    "%BOOTSTRAP_PYTHON%" -m venv "%LOCAL_VENV_PATH%"
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao criar virtualenv local em %LOCAL_VENV_PATH%. Abortando.
        GOTO :FAIL
    )
)

IF NOT EXIST "%ACTIVATE_BAT%" (
    ECHO [ERRO] activate.bat nao encontrado em %ACTIVATE_BAT%. Abortando.
    GOTO :FAIL
)

call "%ACTIVATE_BAT%"
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao ativar o virtualenv local em %LOCAL_VENV_PATH%. Abortando.
    GOTO :FAIL
)

IF NOT EXIST "%PYTHON_EXE%" (
    ECHO [ERRO] Python nao encontrado em %PYTHON_EXE%. Abortando.
    GOTO :FAIL
)

set "LOCAL_PYTHON_VERSION="
for /f "tokens=2 delims= " %%V in ('"%PYTHON_EXE%" -V 2^>^&1') do set "LOCAL_PYTHON_VERSION=%%V"
IF NOT DEFINED LOCAL_PYTHON_VERSION (
    ECHO [ERRO] Nao foi possivel detectar a versao do Python local em %PYTHON_EXE%.
    GOTO :FAIL
)
IF /I NOT "%LOCAL_PYTHON_VERSION%"=="%EXPECTED_PYTHON_VERSION%" (
    ECHO [ERRO] Virtualenv local com Python invalido: encontrado %LOCAL_PYTHON_VERSION%, esperado %EXPECTED_PYTHON_VERSION%.
    ECHO [ERRO] Remova %LOCAL_VENV_PATH% e execute novamente para recriar com a versao correta.
    GOTO :FAIL
)

@REM --- Bootstrap de pip para venvs criados via uv (podem vir sem pip) ---
"%PYTHON_EXE%" -m pip --version >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO [INFO] pip nao encontrado no venv. Tentando bootstrap com ensurepip...
    "%PYTHON_EXE%" -m ensurepip --upgrade
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao bootstrap do pip via ensurepip.
        ECHO [ERRO] Rode manualmente: "%PYTHON_EXE%" -m ensurepip --upgrade
        GOTO :FAIL
    )
    "%PYTHON_EXE%" -m pip --version >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] pip continua indisponivel apos ensurepip. Abortando.
        GOTO :FAIL
    )
)

@REM --- Bootstrap do backend de build (pyproject.toml -> setuptools.build_meta) ---
"%PYTHON_EXE%" -c "import setuptools.build_meta" >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO [INFO] Backend setuptools.build_meta indisponivel. Instalando setuptools e wheel...
    "%PYTHON_EXE%" -m pip install --upgrade setuptools wheel
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao instalar setuptools/wheel no venv local. Abortando.
        GOTO :FAIL
    )
    "%PYTHON_EXE%" -c "import setuptools.build_meta" >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Backend setuptools.build_meta continua indisponivel apos bootstrap. Abortando.
        GOTO :FAIL
    )
)

@REM ==================================================================
@REM ==               CONFIGURACOES DE BUILD DO PYTORCH              ==
@REM ==================================================================
ECHO [INFO] Definindo as flags de build do PyTorch...

@REM --- Estrategia de Build e Runtime ---
set CMAKE_PROJECT_INCLUDE=c:/torch/tweak_runtime.cmake
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
set libuv_ROOT=C:/torch/third_party/libuv/libuv-install
set USE_LIBUV=ON
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

@REM --- Build do wheel do torch ---
"%PYTHON_EXE%" -m pip wheel . -v --no-build-isolation -w dist/
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao gerar wheel do torch. Abortando.
    GOTO :FAIL
)

ECHO [INFO] Processo de build finalizado.
GOTO :SUCCESS

:ENSURE_SUBMODULES_READY
ECHO [INFO] Validando submodules...
set "SUBMODULE_STATUS_FILE=%TEMP%\torch-submodules-%RANDOM%%RANDOM%.txt"
git submodule status --recursive > "%SUBMODULE_STATUS_FILE%" 2>&1
IF ERRORLEVEL 1 (
    ECHO [WARN] Falha ao executar 'git submodule status --recursive'. Tentando reparo forcado de psimd...
    call :REPAIR_PSIMD_SUBMODULE
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao executar 'git submodule status --recursive' e reparo de psimd nao resolveu.
        IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
    git submodule status --recursive > "%SUBMODULE_STATUS_FILE%" 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha persistente em 'git submodule status --recursive' apos reparo de psimd.
        IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
)

findstr /R "^[\-+U]" "%SUBMODULE_STATUS_FILE%" >NUL
IF ERRORLEVEL 2 (
    ECHO [ERRO] Falha ao interpretar o status dos submodules com findstr.
    IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
    IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
    EXIT /B 1
)
IF NOT ERRORLEVEL 1 (
    ECHO [INFO] Detectados submodules ausentes/desalinhados. Executando sync/update...
    git submodule sync --recursive
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha em 'git submodule sync --recursive'.
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
    git submodule update --init --recursive
    IF ERRORLEVEL 1 (
        ECHO [WARN] Falha em 'git submodule update --init --recursive'. Tentando reparo forcado de psimd...
        call :REPAIR_PSIMD_SUBMODULE
        IF ERRORLEVEL 1 (
            ECHO [ERRO] Falha em 'git submodule update --init --recursive' e reparo de psimd nao resolveu.
            IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
            EXIT /B 1
        )
        git submodule update --init --recursive
        IF ERRORLEVEL 1 (
            ECHO [ERRO] Falha persistente em 'git submodule update --init --recursive' apos reparo de psimd.
            IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
            EXIT /B 1
        )
    )
    git submodule status --recursive > "%SUBMODULE_STATUS_FILE%" 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao revalidar estado dos submodules.
        IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
    findstr /R "^[\-+U]" "%SUBMODULE_STATUS_FILE%" >NUL
    IF ERRORLEVEL 2 (
        ECHO [ERRO] Falha ao interpretar o status revalidado dos submodules com findstr.
        IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
    IF NOT ERRORLEVEL 1 (
        ECHO [ERRO] Ainda existem submodules ausentes/desalinhados apos sync/update:
        type "%SUBMODULE_STATUS_FILE%"
        IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
        EXIT /B 1
    )
)

IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1

IF NOT EXIST "%SCRIPT_DIR%third_party\psimd\CMakeLists.txt" (
    ECHO [INFO] Submodule psimd inconsistente. Tentando reparo forcado...
    call :REPAIR_PSIMD_SUBMODULE
    IF ERRORLEVEL 1 (
        EXIT /B 1
    )
)

EXIT /B 0

:REPAIR_PSIMD_SUBMODULE
git submodule deinit -f -- third_party/psimd >NUL 2>&1
IF EXIST ".git\modules\third_party\NNPACK_deps\psimd" rmdir /S /Q ".git\modules\third_party\NNPACK_deps\psimd"
IF EXIST "third_party\psimd" rmdir /S /Q "third_party\psimd"

git submodule sync --recursive third_party/psimd
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha em 'git submodule sync --recursive third_party/psimd'.
    EXIT /B 1
)
git submodule update --init --recursive -- third_party/psimd
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha em 'git submodule update --init --recursive -- third_party/psimd'.
    EXIT /B 1
)
IF NOT EXIST "%SCRIPT_DIR%third_party\psimd\CMakeLists.txt" (
    ECHO [ERRO] psimd segue inconsistente apos reparo forcado.
    ECHO [ERRO] Rode manualmente:
    ECHO [ERRO]   git submodule deinit -f -- third_party/psimd
    ECHO [ERRO]   rmdir /S /Q .git\modules\third_party\NNPACK_deps\psimd
    ECHO [ERRO]   rmdir /S /Q third_party\psimd
    ECHO [ERRO]   git submodule sync --recursive third_party/psimd
    ECHO [ERRO]   git submodule update --init --recursive -- third_party/psimd
    EXIT /B 1
)
EXIT /B 0

:FAIL
popd >NUL 2>&1
EXIT /B 1

:SUCCESS
popd >NUL 2>&1
EXIT /B 0
