@echo off
setlocal enableextensions enabledelayedexpansion

path %SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\

set unattended=no
if "%1"=="/u" set unattended=yes

call :ensure_vista
call :ensure_admin

cd /D %~dp0\..
set launcher_path=%cd%\mpv-h.exe
set mpv_path=%cd%\mpv.exe
set icon_path=%~dp0mpv-icon.ico

if not exist "%launcher_path%" call :die "mpv-h.exe not found"
if not exist "%mpv_path%" call :die "mpv.exe not found"
if not exist "%icon_path%" call :die "mpv-icon.ico not found"

set classes_root_key=HKLM\SOFTWARE\Classes
set app_key=%classes_root_key%\Applications\mpv-h.exe
set capabilities_key=HKLM\SOFTWARE\Clients\Media\mpv-h\Capabilities
set file_associations_key=%capabilities_key%\FileAssociations

call :reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv-h.exe" /d "%launcher_path%" /f
call :reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv-h.exe" /v "UseUrl" /t REG_DWORD /d 1 /f

call :reg add "%app_key%" /v "FriendlyAppName" /d "mpv-h" /f
call :reg add "%app_key%\DefaultIcon" /d "%icon_path%" /f
call :add_verbs "%app_key%"

call :reg add "%classes_root_key%\SystemFileAssociations\video\OpenWithList\mpv-h.exe" /d "" /f
call :reg add "%classes_root_key%\SystemFileAssociations\audio\OpenWithList\mpv-h.exe" /d "" /f

call :reg add "%capabilities_key%" /v "ApplicationName" /d "mpv-h" /f
call :reg add "%capabilities_key%" /v "ApplicationDescription" /d "mpv-h portable launcher with bundled VapourSynth/RIFE environment" /f
call :reg add "HKLM\SOFTWARE\RegisteredApplications" /v "mpv-h" /d "SOFTWARE\Clients\Media\mpv-h\Capabilities" /f

call :add_type "video/x-matroska" "Matroska Video" ".mkv"
call :add_type "video/mp4" "MPEG-4 Video" ".mp4" ".m4v"
call :add_type "video/webm" "WebM Video" ".webm"
call :add_type "video/avi" "AVI Video" ".avi"
call :add_type "video/quicktime" "QuickTime Video" ".mov"
call :add_type "video/x-ms-wmv" "Windows Media Video" ".wmv"
call :add_type "video/x-msvideo" "Video Clip" ".m2ts" ".m2t" ".mts" ".ts" ".flv" ".rmvb"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\mpv-h.lnk');$s.TargetPath='%launcher_path%';$s.WorkingDirectory='%cd%';$s.IconLocation='%icon_path%';$s.Save()"

echo.
echo Installed successfully.
echo Open Windows Default Apps and choose "mpv-h" for video file types.
echo.
if [%unattended%] == [yes] exit 0
<nul set /p =Press any key to open the Default Apps control panel . . .
pause >nul
control /name Microsoft.DefaultPrograms
exit 0

:add_verbs
	set key=%~1
	call :reg add "%key%\shell" /d "play" /f
	call :reg add "%key%\shell\open" /v "LegacyDisable" /f
	call :reg add "%key%\shell\open\command" /d "\"%launcher_path%\" -- \"%%%%L\"" /f
	call :reg add "%key%\shell\play" /d "&Play" /f
	call :reg add "%key%\shell\play\command" /d "\"%launcher_path%\" -- \"%%%%L\"" /f
	goto :EOF

:add_type
	set friendly_name=%~2
	if not [%~3] == [] call :add_one_type "%friendly_name%" "%~3"
	if not [%~4] == [] call :add_one_type "%friendly_name%" "%~4"
	if not [%~5] == [] call :add_one_type "%friendly_name%" "%~5"
	if not [%~6] == [] call :add_one_type "%friendly_name%" "%~6"
	if not [%~7] == [] call :add_one_type "%friendly_name%" "%~7"
	if not [%~8] == [] call :add_one_type "%friendly_name%" "%~8"
	if not [%~9] == [] call :add_one_type "%friendly_name%" "%~9"
	goto :EOF

:add_one_type
	set friendly_name=%~1
	set extension=%~2
	set prog_id=io.mpv-h!extension!
	set prog_id=!prog_id:.=!
	set extension_key=%classes_root_key%\!extension!
	set prog_id_key=%classes_root_key%\!prog_id!

	call :reg add "!prog_id_key!" /d "%friendly_name%" /f
	call :reg add "!prog_id_key!" /v "EditFlags" /t REG_DWORD /d 65536 /f
	call :reg add "!prog_id_key!" /v "FriendlyTypeName" /d "%friendly_name%" /f
	call :reg add "!prog_id_key!\DefaultIcon" /d "%icon_path%" /f
	call :add_verbs "!prog_id_key!"
	call :reg add "!extension_key!\OpenWithProgIds" /v "!prog_id!" /f
	call :reg add "%app_key%\SupportedTypes" /v "!extension!" /f
	call :reg add "%file_associations_key%" /v "!extension!" /d "!prog_id!" /f
	goto :EOF

:ensure_admin
	openfiles >nul 2>&1
	if errorlevel 1 (
		echo This batch script requires administrator privileges. Right-click on
		echo mpv-h-install.bat and select "Run as administrator".
		call :die
	)
	goto :EOF

:ensure_vista
	ver | find "XP" >nul
	if not errorlevel 1 (
		echo This batch script only works on Windows Vista and later.
		call :die
	)
	goto :EOF

:reg
	>nul reg %*
	if errorlevel 1 set error=yes
	if [%error%] == [yes] echo Error in command: reg %*
	if [%error%] == [yes] call :die
	goto :EOF

:die
	if not [%1] == [] echo %~1
	if [%unattended%] == [yes] exit 1
	pause
	exit 1

