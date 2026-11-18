@echo off
REM Copia os assets do mod Parallax (pasta extraida) para dentro da Forever Engine.
REM Uso: copiar_assets.bat "C:\caminho\Parallax" "C:\caminho\Forever-Engine-master"
if "%~2"=="" (
  echo Uso: copiar_assets.bat "pasta Parallax" "pasta Forever-Engine-master"
  exit /b 1
)
set SRC=%~1
set DST=%~2
xcopy "%SRC%\images" "%DST%\assets\images" /E /I /Y
xcopy "%SRC%\shaders" "%DST%\assets\shaders" /E /I /Y
xcopy "%SRC%\fonts" "%DST%\assets\fonts" /E /I /Y
xcopy "%SRC%\sounds" "%DST%\assets\sounds" /E /I /Y
xcopy "%SRC%\music" "%DST%\assets\music" /E /I /Y
copy /Y "%SRC%\songs\Expulsion\song\Inst.ogg" "%DST%\assets\songs\expulsion\Inst.ogg"
copy /Y "%SRC%\songs\Expulsion\song\Voices.ogg" "%DST%\assets\songs\expulsion\Voices.ogg"
REM remove o atlas original gigante (415 MB de textura); o jogo usa SchoolhouseA/B
del /Q "%DST%\assets\images\bgs\educator\Schoolhouse.png" "%DST%\assets\images\bgs\educator\Schoolhouse.xml"
xcopy "assets\songs\expulsion" "%DST%\assets\songs\expulsion" /E /I /Y
echo Pronto.
