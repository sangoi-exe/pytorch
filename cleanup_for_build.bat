@echo off
setlocal enabledelayedexpansion

echo ================================================
echo    Limpeza Controlada da Build do PyTorch
echo ================================================
echo.

:: Definir diretório base (onde está o setup.py)
set "BASE_DIR=%CD%"
if not exist "%BASE_DIR%\setup.py" (
    echo ERRO: setup.py nao encontrado no diretorio atual!
    echo Execute este script na pasta raiz do pytorch
    pause
    exit /b 1
)

echo Diretorio base: %BASE_DIR%
echo.

:: Confirmar antes de prosseguir
set /p "CONFIRM=Deseja continuar com a limpeza? (S/n): "
if /i "!CONFIRM!" neq "S" if /i "!CONFIRM!" neq "" (
    echo Operacao cancelada pelo usuario.
    pause
    exit /b 0
)

echo.
echo Iniciando limpeza...
echo.

:: 1. Remover pasta build/ completa
if exist "build" (
    echo [1/8] Removendo pasta build/...
    rmdir /s /q "build" 2>nul
    if exist "build" (
        echo   AVISO: Alguns arquivos em build/ podem estar em uso
    ) else (
        echo   OK: build/ removida
    )
) else (
    echo [1/8] Pasta build/ ja nao existe
)

:: 2. Remover pasta dist/ completa
if exist "dist" (
    echo [2/8] Removendo pasta dist/...
    rmdir /s /q "dist" 2>nul
    if exist "dist" (
        echo   AVISO: Alguns arquivos em dist/ podem estar em uso
    ) else (
        echo   OK: dist/ removida
    )
) else (
    echo [2/8] Pasta dist/ ja nao existe
)

:: 3. Remover arquivos *.egg-info
echo [3/8] Removendo arquivos *.egg-info...
for /d %%i in (*.egg-info) do (
    echo   Removendo: %%i
    rmdir /s /q "%%i" 2>nul
)

:: 4. Remover cache Python __pycache__
echo [4/8] Removendo cache Python (__pycache__)...
for /r . %%i in (__pycache__) do (
    if exist "%%i" (
        echo   Removendo: %%i
        rmdir /s /q "%%i" 2>nul
    )
)

:: 5. Remover arquivos .pyc e .pyo
echo [5/8] Removendo arquivos .pyc e .pyo...
del /s /q "*.pyc" 2>nul
del /s /q "*.pyo" 2>nul

:: 6. Remover arquivos temporários do CMake
echo [6/8] Removendo cache do CMake...
if exist "CMakeCache.txt" (
    echo   Removendo: CMakeCache.txt
    del /q "CMakeCache.txt" 2>nul
)
if exist "CMakeFiles" (
    echo   Removendo: CMakeFiles/
    rmdir /s /q "CMakeFiles" 2>nul
)

:: 7. Remover objetos específicos do PyTorch
echo [7/8] Removendo objetos específicos do PyTorch...
if exist "torch\version.py" (
    echo   Removendo: torch\version.py (gerado automaticamente)
    del /q "torch\version.py" 2>nul
)

:: 8. Remover arquivos temporários do setuptools
echo [8/8] Removendo arquivos temporários do setuptools...
for %%i in (.eggs .pytest_cache .coverage) do (
    if exist "%%i" (
        echo   Removendo: %%i
        if exist "%%i\*" (
            rmdir /s /q "%%i" 2>nul
        ) else (
            del /q "%%i" 2>nul
        )
    )
)

echo.
echo ================================================
echo              LIMPEZA CONCLUIDA
echo ================================================
echo.

:: Mostrar o que foi preservado
echo Arquivos/pastas PRESERVADOS:
if exist "venv" echo   - venv/
if exist "venv-build" echo   - venv-build/
if exist "venv-runtime" echo   - venv-runtime/
for /d %%i in (venv*) do echo   - %%i/
echo   - .git/
echo   - .gitignore
echo   - codigo fonte (.py, .cpp, .h, etc.)
echo   - arquivos de configuracao

echo.
echo Pronto para executar: python setup.py bdist_wheel
pause
