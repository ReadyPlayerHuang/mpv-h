@echo off
setlocal enableextensions enabledelayedexpansion

path %SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\

call :ensure_admin

set classes_root_key=HKLM\SOFTWARE\Classes

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv-h.exe" /f >nul 2>&1
reg delete "%classes_root_key%\Applications\mpv-h.exe" /f >nul 2>&1
reg delete "%classes_root_key%\SystemFileAssociations\video\OpenWithList\mpv-h.exe" /f >nul 2>&1
reg delete "%classes_root_key%\SystemFileAssociations\audio\OpenWithList\mpv-h.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "mpv-h" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Clients\Media\mpv-h\Capabilities" /f >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\mpv-h.lnk" >nul 2>&1

for /f "usebackq eol= delims=" %%k in (`reg query "%classes_root_key%" /f "io.mpv-h*" /s /v /c`) do (
	echo %%k| findstr /r /i "^HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\\.[^\\][^\\]*\\OpenWithProgIds$" >nul
	if not errorlevel 1 (
		for /f "usebackq eol= tokens=1" %%v in (`reg query "%%k" /f "io.mpv-h*" /v /c`) do (
			echo %%v| findstr /r /i "^io.mpv-h" >nul
			if not errorlevel 1 reg delete "%%k" /v "%%v" /f >nul 2>&1
		)
	)
)

for /f "usebackq eol= delims=" %%k in (`reg query "%classes_root_key%" /f "io.mpv-h*" /k /c`) do (
	echo %%k| findstr /r /i "^HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\io\.mpv-h" >nul
	if not errorlevel 1 reg delete "%%k" /f >nul 2>&1
)

echo mpv-h registration removed.
pause
exit 0

:ensure_admin
	openfiles >nul 2>&1
	if errorlevel 1 (
		echo This batch script requires administrator privileges. Right-click on
		echo mpv-h-uninstall.bat and select "Run as administrator".
		pause
		exit 1
	)
	goto :EOF

