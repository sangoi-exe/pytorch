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
set "SCRIPT_DIR_FWD=%SCRIPT_DIR:\=/%"
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
IF NOT DEFINED BOOTSTRAP_PYTHON (
    set "BOOTSTRAP_PYTHON=C:\Users\lucas\OneDrive\Documentos\stable-diffusion-webui-codex\.venv\Scripts\python.exe"
)
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

@REM --- Dependencia Python exigida pelo setup.py (check_pydep) ---
"%PYTHON_EXE%" -c "import yaml" >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO [INFO] Modulo yaml ausente. Instalando pyyaml...
    "%PYTHON_EXE%" -m pip install --upgrade pyyaml
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao instalar pyyaml no venv local. Abortando.
        GOTO :FAIL
    )
    "%PYTHON_EXE%" -c "import yaml" >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Modulo yaml continua indisponivel apos instalar pyyaml. Abortando.
        GOTO :FAIL
    )
)

@REM --- NumPy para evitar fallback/warning em CMake (USE_NUMPY=ON) ---
"%PYTHON_EXE%" -c "import numpy" >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO [INFO] Modulo numpy ausente. Instalando numpy...
    "%PYTHON_EXE%" -m pip install --upgrade numpy
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Falha ao instalar numpy no venv local. Abortando.
        GOTO :FAIL
    )
    "%PYTHON_EXE%" -c "import numpy" >NUL 2>&1
    IF ERRORLEVEL 1 (
        ECHO [ERRO] Modulo numpy continua indisponivel apos instalacao. Abortando.
        GOTO :FAIL
    )
)

@REM --- Dependencia de codegen usada por torchgen (assert_never/Self) ---
ECHO [INFO] Garantindo typing-extensions>=4.10.0...
"%PYTHON_EXE%" -m pip install --upgrade "typing-extensions>=4.10.0"
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao instalar typing-extensions no venv local. Abortando.
    GOTO :FAIL
)
"%PYTHON_EXE%" -c "import importlib.metadata as m,re,sys; v=m.version('typing-extensions'); p=tuple(int(x) for x in re.findall(r'[0-9]+', v)[:3]); sys.exit(0 if p >= (4,10,0) else 1)" >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO [ERRO] typing-extensions com versao invalida no venv local. Esperado >= 4.10.0.
    GOTO :FAIL
)

@REM ==================================================================
@REM ==               CONFIGURACOES DE BUILD DO PYTORCH              ==
@REM ==================================================================
ECHO [INFO] Definindo as flags de build do PyTorch...

@REM --- Estrategia de Build e Runtime ---
set "CMAKE_PROJECT_INCLUDE=%SCRIPT_DIR_FWD%tweak_runtime.cmake"
IF NOT EXIST "%SCRIPT_DIR%tweak_runtime.cmake" (
    ECHO [ERRO] Arquivo obrigatorio tweak_runtime.cmake nao encontrado em %SCRIPT_DIR%.
    GOTO :FAIL
)
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
set USE_CUSPARSELT=OFF
set USE_CUDSS=OFF

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
set "libuv_ROOT=%SCRIPT_DIR_FWD%third_party/libuv/libuv-install"
set USE_LIBUV=ON
set USE_DISTRIBUTED=ON
set USE_GLOO=ON
set USE_MPI=OFF
set USE_XPU=OFF
set USE_MPS=OFF
set CAN_COMPILE_METAL=OFF
set USE_COREML_DELEGATE=OFF
set USE_GLOO_WITH_OPENSSL=OFF
set USE_TENSORPIPE=OFF
set USE_KLEIDIAI=OFF

@REM --- Ferramentas e Subprojetos Desativados ---
set BUILD_FUNCTORCH=OFF
set ONNX_BUILD_TESTS=OFF
set USE_LITE_PROTO=OFF
set CMAKE_VERBOSE_MAKEFILE=OFF

@REM --- Profiling e Debug Desativados ---
set USE_ITT=OFF
set USE_KINETO=OFF
set PRINT_CMAKE_DEBUG_INFO=OFF
set USE_SOURCE_DEBUG_ON_MOBILE=OFF

@REM --- Variaveis de Performance ---
IF NOT DEFINED MAX_JOBS (
    IF /I "%USE_FLASH_ATTENTION%"=="ON" (
        set MAX_JOBS=4
    ) ELSE (
        set MAX_JOBS=16
    )
)
IF DEFINED CMAKE_BUILD_PARALLEL_LEVEL (
    ECHO [WARN] CMAKE_BUILD_PARALLEL_LEVEL e ignorado neste launcher; usando MAX_JOBS.
    set CMAKE_BUILD_PARALLEL_LEVEL=
)
IF NOT DEFINED TORCH_NVCC_FLAGS set TORCH_NVCC_FLAGS=--threads 1
ECHO [INFO] Paralelismo de build configurado: MAX_JOBS=%MAX_JOBS%, TORCH_NVCC_FLAGS=%TORCH_NVCC_FLAGS%

@REM --- Arquiteturas CUDA ---
set TORCH_CUDA_ARCH_LIST=8.6

call :ENSURE_LIBUV_RUNTIME
IF ERRORLEVEL 1 (
    GOTO :FAIL
)

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

:ENSURE_LIBUV_RUNTIME
IF /I NOT "%USE_LIBUV%"=="ON" (
    EXIT /B 0
)

set "LIBUV_ROOT_PATH=%libuv_ROOT%"
IF "%LIBUV_ROOT_PATH%"=="" (
    set "LIBUV_ROOT_PATH=%SCRIPT_DIR%third_party\libuv\libuv-install"
)
set "LIBUV_DLL="

IF EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\lib\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\lib\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\lib\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\lib\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\..\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\..\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\uv.dll"

IF NOT "%LIBUV_DLL%"=="" (
    set "libuv_ROOT=%LIBUV_ROOT_PATH%"
    ECHO [INFO] libuv runtime resolvido: %LIBUV_DLL%
    EXIT /B 0
)

ECHO [INFO] uv.dll nao encontrado em %LIBUV_ROOT_PATH%. Compilando/instalando libuv...
set "LIBUV_SRC=%SCRIPT_DIR%third_party\libuv"
set "LIBUV_BUILD=%LIBUV_SRC%\build-codex"

IF NOT EXIST "%LIBUV_SRC%\CMakeLists.txt" (
    ECHO [ERRO] Codigo-fonte do libuv nao encontrado em %LIBUV_SRC%.
    ECHO [ERRO] Verifique submodule third_party/libuv.
    EXIT /B 1
)

cmake -S "%LIBUV_SRC%" -B "%LIBUV_BUILD%" -G Ninja -DCMAKE_BUILD_TYPE=Release -DLIBUV_BUILD_SHARED=ON -DLIBUV_BUILD_TESTS=OFF -DLIBUV_BUILD_BENCH=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="%LIBUV_ROOT_PATH%"
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao configurar build do libuv.
    EXIT /B 1
)

cmake --build "%LIBUV_BUILD%" --config Release --target install
IF ERRORLEVEL 1 (
    ECHO [ERRO] Falha ao compilar/instalar libuv.
    EXIT /B 1
)

set "LIBUV_FALLBACK_COPY_USED=0"
IF NOT EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" (
    IF NOT EXIST "%LIBUV_ROOT_PATH%\bin" (
        mkdir "%LIBUV_ROOT_PATH%\bin"
        IF ERRORLEVEL 1 (
            ECHO [ERRO] Falha ao criar diretorio de runtime do libuv em %LIBUV_ROOT_PATH%\bin.
            EXIT /B 1
        )
    )
    IF EXIST "%LIBUV_BUILD%\uv.dll" copy /Y "%LIBUV_BUILD%\uv.dll" "%LIBUV_ROOT_PATH%\bin\uv.dll" >NUL
    IF NOT EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" IF EXIST "%LIBUV_BUILD%\Release\uv.dll" copy /Y "%LIBUV_BUILD%\Release\uv.dll" "%LIBUV_ROOT_PATH%\bin\uv.dll" >NUL
    IF NOT EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" IF EXIST "%LIBUV_BUILD%\bin\uv.dll" copy /Y "%LIBUV_BUILD%\bin\uv.dll" "%LIBUV_ROOT_PATH%\bin\uv.dll" >NUL
    IF NOT EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" IF EXIST "%LIBUV_BUILD%\bin\Release\uv.dll" copy /Y "%LIBUV_BUILD%\bin\Release\uv.dll" "%LIBUV_ROOT_PATH%\bin\uv.dll" >NUL
    IF EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" set "LIBUV_FALLBACK_COPY_USED=1"
)

set "LIBUV_DLL="
IF EXIST "%LIBUV_ROOT_PATH%\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\lib\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\lib\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\lib\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\lib\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\Release\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\Release\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\..\..\bin\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\..\..\bin\uv.dll"
IF "%LIBUV_DLL%"=="" IF EXIST "%LIBUV_ROOT_PATH%\uv.dll" set "LIBUV_DLL=%LIBUV_ROOT_PATH%\uv.dll"

IF "%LIBUV_DLL%"=="" (
    ECHO [ERRO] libuv foi compilado, mas uv.dll nao foi encontrado em %LIBUV_ROOT_PATH%.
    EXIT /B 1
)

set "libuv_ROOT=%LIBUV_ROOT_PATH%"
IF "%LIBUV_FALLBACK_COPY_USED%"=="1" (
    ECHO [WARN] uv.dll nao foi encontrado no install prefix do libuv; foi aplicado fallback de copia do build tree.
)
ECHO [INFO] libuv runtime resolvido: %LIBUV_DLL%
EXIT /B 0

:ENSURE_SUBMODULES_READY
ECHO [INFO] Validando submodules...
set "SUBMODULE_STATUS_FILE=%TEMP%\torch-submodules-%RANDOM%%RANDOM%.txt"
git submodule status --recursive > "%SUBMODULE_STATUS_FILE%" 2>&1
IF ERRORLEVEL 1 (
    ECHO [WARN] Falha ao executar 'git submodule status --recursive'. Tentando reparo forcado de psimd...
    IF NOT EXIST "%SCRIPT_DIR%third_party\psimd\CMakeLists.txt" (
        call :REPAIR_PSIMD_SUBMODULE
        IF ERRORLEVEL 1 (
            ECHO [ERRO] Falha ao executar 'git submodule status --recursive' e reparo de psimd nao resolveu.
            IF EXIST "%SUBMODULE_STATUS_FILE%" type "%SUBMODULE_STATUS_FILE%"
            IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
            EXIT /B 1
        )
    ) ELSE (
        ECHO [ERRO] Falha ao executar 'git submodule status --recursive' e psimd aparenta consistente.
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
        IF NOT EXIST "%SCRIPT_DIR%third_party\psimd\CMakeLists.txt" (
            call :REPAIR_PSIMD_SUBMODULE
            IF ERRORLEVEL 1 (
                ECHO [ERRO] Falha em 'git submodule update --init --recursive' e reparo de psimd nao resolveu.
                IF EXIST "%SUBMODULE_STATUS_FILE%" del /Q "%SUBMODULE_STATUS_FILE%" >NUL 2>&1
                EXIT /B 1
            )
        ) ELSE (
            ECHO [ERRO] Falha em 'git submodule update --init --recursive' sem indicio de corrupcao no psimd.
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

IF NOT EXIST "%SCRIPT_DIR%third_party\fbgemm\external\asmjit\CMakeLists.txt" (
    ECHO [ERRO] Submodule inconsistente: third_party\fbgemm\external\asmjit - faltando CMakeLists.txt.
    EXIT /B 1
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
