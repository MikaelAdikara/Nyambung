@echo off
rem Nyambung: jalankan server + papan pantau terapis, lalu buka browser.
rem Data demo ILUSTRATIF di server\data\demo.db. Akun: rina@demo.nyambung.id / nyambung-demo
setlocal
cd /d "%~dp0"
set "ROOT=%~dp0"
set "PY=%ROOT%server\.venv\Scripts\python.exe"
set "NYAMBUNG_DB_PATH=%ROOT%server\data\demo.db"

if not exist "%PY%" (
  echo [1/4] Membuat virtualenv server...
  python -m venv server\.venv || goto :fail
  "%PY%" -m pip install -q -r server\requirements.txt || goto :fail
)

if not exist "dashboard\node_modules" (
  echo [1/4] Memasang paket papan pantau...
  pushd dashboard
  call npm install || (popd & goto :fail)
  popd
)

echo [2/4] Menyiapkan akun demo terapis (yang sudah ada dilewati)...
"%PY%" tools\create_therapist.py --demo || goto :fail

echo [3/4] Menyalakan server dan papan pantau di jendela terpisah...
start "Nyambung server :8000" cmd /k ""%PY%" -m uvicorn app.main:app --app-dir server --host 0.0.0.0 --port 8000"
start "Nyambung papan pantau :5173" /D "%ROOT%dashboard" cmd /k "npm run dev"

echo [4/4] Menunggu server siap...
set /a TRIES=0
:wait_server
curl.exe -s -m 2 http://127.0.0.1:8000/v1/health | findstr /c:"true" >nul && goto :wait_dash
set /a TRIES+=1
if %TRIES% geq 60 goto :fail_server
ping -n 2 127.0.0.1 >nul
goto :wait_server

:wait_dash
curl.exe -s -m 2 -o nul http://127.0.0.1:5173/ && goto :ready
set /a TRIES+=1
if %TRIES% geq 90 goto :fail_dash
ping -n 2 127.0.0.1 >nul
goto :wait_dash

:ready
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(Find-NetRoute -RemoteIPAddress 8.8.8.8 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress"`) do set "LANIP=%%i"
start "" http://127.0.0.1:5173
echo.
echo  Papan pantau : http://127.0.0.1:5173
echo  Masuk        : rina@demo.nyambung.id  /  nyambung-demo   (ILUSTRATIF)
echo  Server HP    : http://%LANIP%:8000
echo.
echo  Build APK untuk HP keluarga (di folder app):
echo    flutter build apk --release --split-per-abi --dart-define=NYAMBUNG_SERVER=http://%LANIP%:8000
echo.
echo  HP dan laptop harus di Wi-Fi yang sama. Tutup dua jendela "Nyambung" untuk mematikan.
echo.
pause
exit /b 0

:fail_server
echo Server tidak menjawab di http://127.0.0.1:8000. Lihat jendela "Nyambung server".
pause
exit /b 1

:fail_dash
echo Papan pantau tidak menjawab di http://127.0.0.1:5173. Lihat jendela "Nyambung papan pantau".
pause
exit /b 1

:fail
echo Gagal menyiapkan. Periksa pesan di atas.
pause
exit /b 1
