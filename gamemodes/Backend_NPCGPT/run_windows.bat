@echo off
setlocal
cd /d %~dp0

if not exist ".env" (
  if exist ".env.example" (
    copy ".env.example" ".env" >nul
    echo Criado .env a partir do .env.example. Edite o .env e coloque suas chaves.
  ) else (
    echo ERRO: .env.example nao encontrado.
    pause
    exit /b 1
  )
)

echo Instalando dependencias...
npm i
if errorlevel 1 (
  echo Falhou npm i.
  pause
  exit /b 1
)

echo Iniciando backend...
npm start
