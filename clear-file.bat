:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 타겟 디렉토리 아래에 유효기간이 지난 파일을 삭제
:: - clear-file.bat {dir_path} {exp_date} {recsv} {ext}
:: - [required] dir_path: 타겟 디렉토리 경로
:: - [optional] exp_date: 유효기간 (기본값 30일)
:: - [optional] recsv: 하위 디렉토리 재귀적 검색 true/false (기본값 false)
:: - [optional] ext: 타겟 파일 확장자 ('.' 없이 입력. 전체 파일 대상인 경우 기본값 all)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
@chcp 65001 1> NUL 2> NUL
setlocal enabledelayedexpansion

set LOG=clear-file-log_%date:-=%.txt

::::::::::::::::::::::::::::::::::::::::::
:: help
::::::::::::::::::::::::::::::::::::::::::
IF "%1" == "help" (
  echo 'clear-file.bat {dir_path} {exp_date} {recsv} {ext}'
  echo - [required] dir_path: 타겟 디렉토리 경로
  echo - [optional] exp_date: 유효기간 ^(기본값 30일^)
  echo - [optional] recsv: 하위 디렉토리 재귀적 검색 true/false ^(기본값 false^)
  echo - [optional] ext: 타겟 파일 확장자 ^('.' 없이 입력. 전체 파일 대상인 경우 기본값 all^)
  pause
  exit /b
)

::::::::::::::::::::::::::::::::::::::::::
:: reset log file
::::::::::::::::::::::::::::::::::::::::::
echo clear-file.bat start > %LOG%

::::::::::::::::::::::::::::::::::::::::::
:: get param
::::::::::::::::::::::::::::::::::::::::::
set dir_path=%1
set exp_date=%2
set recsv=%3
set ext=%4

::::::::::::::::::::::::::::::::::::::::::
:: check param
::::::::::::::::::::::::::::::::::::::::::
IF "%dir_path%" == "" (
  echo command error. try 'clear-file.bat help'>> %LOG%
  exit /b
)

IF "%exp_date%" == "" (
  set exp_date=30
)

IF "%recsv%" == "" (
  set recsv=false
)

IF NOT "%recsv%" == "true" (
  IF NOT "%recsv%" == "false" (
    echo command error. try 'clear-file.bat help'>> %LOG%
    exit /b
  )
)

IF "%ext%" == "" (
  set ext=all
)

echo dir_path: %dir_path% >> %LOG%
echo exp_date: %exp_date% >> %LOG%
echo recsv: %recsv% >> %LOG%
echo ext: %ext% >> %LOG%

::::::::::::::::::::::::::::::::::::::::::
:: check directory
::::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%dir_path%" (
  echo not found directory. path: %dir_path% >> %LOG%
  exit /b
)

::::::::::::::::::::::::::::::::::::::::::
:: set command
::::::::::::::::::::::::::::::::::::::::::
set command=forfiles /P %dir_path% /D -%exp_date%

IF "%recsv%" == "true" (
  set command=%command% /S
)
IF NOT "%ext%" == "all" (
  set command=%command% /M *.%ext%
)

set command=%command% /C "cmd /c @echo @path @fdate"

echo: >> %LOG%
echo search and delete file start >> %LOG%
echo ^> %command% >> %LOG%

::::::::::::::::::::::::::::::::::::::::::
:: get file list
::::::::::::::::::::::::::::::::::::::::::
FOR /F "tokens=*" %%F IN ('%command%') DO (
  set data=%%F
  
  :: parse data
  FOR /F "usebackq tokens=1" %%a IN (`powershell -Command "$str='!data!'; $idx=$str.LastIndexOf(' '); write-output $idx"`) DO (
    set file_path=!data:~1,%%a!

    :: check file
    IF NOT EXIST "!file_path!\*" (
      FOR /F "usebackq tokens=1" %%b IN (`powershell -Command "$file_path='!file_path!'; $len=$file_path.Length; $next_idx=$len+3; write-output $next_idx"`) DO (
        set mod_date=!data:~%%b!
      )

      echo file path: !file_path!, last modify date: !mod_date! >> %LOG%
      
      :: delete file
      del !file_path!
    )
  )
)

exit /b