::-------------------------------------------------------------------------------------
:: LICENSE -------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::	This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
::
::    Copyright (C) 2013  jb_alvarado
::
::    This program is free software: you can redistribute it and/or modify
::    it under the terms of the GNU General Public License as published by
::    the Free Software Foundation, either version 3 of the License, or
::    (at your option) any later version.
::
::    This program is distributed in the hope that it will be useful,
::    but WITHOUT ANY WARRANTY; without even the implied warranty of
::    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::    GNU General Public License for more details.
::
::    You should have received a copy of the GNU General Public License
::    along with this program.  If not, see <http://www.gnu.org/licenses/>.
::-------------------------------------------------------------------------------------
::-------------------------------------------------------------------------------------

::-------------------------------------------------------------------------------------
:: History ---------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::
::  This is version 0.81
::	Project stared at 2013-09-24. Last bigger modification was on 2013-11-06
::	2013-09-29 add ffmpeg, rtmp and other tools
::	2013-09-30 reorder code and some small things
::  2013-10-01 change pkg-config, add mp4box, and reorder code
::	2013-10-03 add libs (faac, and some others) and change ffmpeg download to github
::	2013-10-06 build the environment new and remove openssl and rtmp
::	2013-10-08 add libopus and libvpx (thanks to hoary)
::	2013-10-10 add libass and add build check to the shell scripts
::	2013-10-13 add libbluray, openjpeg and finally librtmp to ffmpeg
::	2013-10-14 add utvideo to ffmpeg and change profile parameter to static
::	2013-10-19 add xavs and opus-tools, update svn and opus version
:: 2013-10-22 some fixes and add mplayer (maybe not the best way)
:: 2013-11-05 update libbluray, fontconfig, add libxml2 and add update function to ffmpeg
:: 2013-11-06 add openexr, jpeg2000, gettext and imagemagick
::
::-------------------------------------------------------------------------------------

@echo off
color 87
title media-autobuild_suite

set instdir=%CD%

::------------------------------------------------------------------
::configure build system:
::------------------------------------------------------------------

:selectSystem
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Select the build target system:
echo. 1 = both (32 bit and 64 bit)
echo. 2 = 32 bit build system
echo. 3 = 64 bit build system
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P buildEnv="Build System:"

if %buildEnv%==1 (
	set "build32=yes"
	set "build64=yes"
	)
if %buildEnv%==2 (
	set "build32=yes"
	set "build64=no"
	)
if %buildEnv%==3 (
	set "build32=no"
	set "build64=yes"
	)
if %buildEnv% GTR 3 GOTO :selectSystem

:selectNonFree
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Build nonfree binaries (like fdkaac), is not allow to distribute them:
echo. 1 = nonfree binaries
echo. 2 = free binaries
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P nonfree="Binaries:"

if %nonfree%==1 (
	set "binary=y"
	)
if %nonfree%==2 (
	set "binary=n"
	)
if %nonfree% GTR 2 GOTO selectNonFree

:mp4boxStatic
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Build static mp4box binary:
echo. 1 = yes
echo. 2 = no
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P buildMp4box="build mp4box:"

if %buildMp4box%==1 (
	set "mp4box=y"
	)
if %buildMp4box%==2 (
	set "mp4box=n"
	)
if %buildMp4box% GTR 2 GOTO mp4boxStatic

:mplayer
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Build static mplayer/mencoder binary:
echo. 1 = yes
echo. 2 = no
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P buildmplayer="build mplayer:"

if %buildmplayer%==1 (
	set "mplayer=y"
	)
if %buildmplayer%==2 (
	set "mplayer=n"
	)
if %buildmplayer% GTR 2 GOTO mplayer

:ffmpeg
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Build static ffmpeg binary:
echo. 1 = yes
echo. 2 = no
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P buildffmpeg="build ffmpeg:"

if %buildffmpeg%==1 (
	set "ffmpeg=y"
	)
if %buildffmpeg%==2 (
	set "ffmpeg=n"
	)
if %buildffmpeg% GTR 2 GOTO ffmpeg

:magick
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Build static ImageMagick binary:
echo. 1 = yes
echo. 2 = no
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P buildmagick="build ImageMagick:"

if %buildmagick%==1 (
	set "magick=y"
	)
if %buildmagick%==2 (
	set "magick=n"
	)
if %buildmagick% GTR 2 GOTO magick

:numCores
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
echo.
echo. Number of CPU Cores/Threads for compiling:
echo. (it is non-recommended to use all cores/threads!)
echo.
echo -------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------
set /P cpuCores="Core/Thread Count:"
echo -------------------------------------------------------------------------------

for /l %%a in (1,1,%cpuCores%) do (
	set cpuCount=%%a
	)
if "%cpuCount%"=="" GOTO :numCores	

::------------------------------------------------------------------
::download and install basic msys system:
::------------------------------------------------------------------

if exist "%instdir%\msys\1.0\msys.bat" GOTO 7za
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install msys basic system
	echo.
	echo -------------------------------------------------------------------------------
	
	echo.var wshell = new ActiveXObject("WScript.Shell");var htmldoc = new ActiveXObject("htmlfile");var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP");var adodb = new ActiveXObject("ADODB.Stream");var FSO = new ActiveXObject("Scripting.FileSystemObject");;function http_get(url, is_binary){ xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4);  WScript.Sleep(100); if (xmlhttp.status != 200) { WScript.Echo("http get failed: " + xmlhttp.status);  WScript.Quit(2); }; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText;}; function url_decompose_filename(url) { return url.split('/').pop().split('?').shift(); }; function save_binary(path, data) { adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2);}; function pick_from_sf_file_list(html, cond) { htmldoc.open(); htmldoc.write(html); var tr = htmldoc.getElementById("files_list").getElementsByTagName("tr"); for (var i = 0; i ^< tr.length; ++i) {  title = tr[i].title;  if (cond(title)) return title; }; return null;}; function download_mingw_get() { var base_url = "http://sourceforge.net/projects/mingw/files/Installer/mingw-get/"; var html = http_get(base_url, false); var project_name = pick_from_sf_file_list(html, function(title) { return title.indexOf("mingw-get") ^>= 0; }); var project_url = base_url + project_name + "/"; html = http_get(project_url, false); var dlp_name = pick_from_sf_file_list(html, function(title) { return title.indexOf("bin.zip") ^>= 0; }); var dlp_url = project_url + dlp_name + "/download"; html = http_get(dlp_url, false); htmldoc.open(); htmldoc.write(html); var div = htmldoc.getElementById("downloading"); var url = div.getElementsByTagName("a")[1].href; var filename = url.split('/').pop().split('?').shift(); var installer_data = http_get(url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename) }; function extract_zip(zip_file, dstdir) { var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0);}; function install_mingw(zip_file, packages) { var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir); wshell.Run("bin\\mingw-get install " + packages, 10, true); var fstab = FSO.GetAbsolutePathName("msys\\1.0\\etc\\fstab"); var fp = FSO.CreateTextFile(fstab, true); fp.WriteLine(rootdir.replace(/\\/g,"/") + "\t/mingw"); fp.Close(); FSO.GetFile(zip_file).Delete();}; var packages = "msys-base msys-coreutils msys-wget msys-zip msys-unzip"; install_mingw(download_mingw_get(), packages)>>build_msys.js
	
	cscript build_msys.js
	del build_msys.js
	del mingw-get-0.6*

:7za
if exist "%instdir%\opt\bin\7za.exe" GOTO mingw-dtk
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install 7za
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\wget.exe -c "http://downloads.sourceforge.net/sevenzip/7za920.zip"
	mkdir opt
	cd opt
	mkdir bin
	mkdir doc
	cd doc
	mkdir 7za920
	cd ..
	cd bin
	%instdir%\msys\1.0\bin\unzip %instdir%/7za920.zip
	%instdir%\msys\1.0\bin\mv license.txt readme.txt 7-zip.chm ../doc/7za920
	cd ..\..
	del 7za920.zip
	
:mingw-dtk
if exist "%instdir%\bin\msgmerge.exe" GOTO mingw32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install ming-developer-toolkit
	echo.
	echo -------------------------------------------------------------------------------
	del /Q %instdir%\var\lib\mingw-get\data\mingw*
	%instdir%\msys\1.0\bin\wget.exe -c "http://blog.pixelcrusher.de/downloads/media-autobuild_suite/mingw-dtk_jb.zip"
	cd %instdir%\var\lib\mingw-get\data
	%instdir%\opt\bin\7za.exe x %instdir%\mingw-dtk_jb.zip
	cd %instdir%
	del mingw-dtk_jb.zip
	%instdir%\bin\mingw-get install mingw-developer-toolkit pkginfo
	%instdir%\bin\mingw-get upgrade msys-core-bin=1.0.17-1

::------------------------------------------------------------------
::download and install mingw compiler:
::------------------------------------------------------------------	
	
:mingw32
if %build32%==yes (
	if exist "%instdir%\mingw32\bin\gcc.exe" GOTO mingw64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- Download and install mingw 32bit compiler to mingw32
		echo.
		echo -------------------------------------------------------------------------------
		if exist mingw32-gcc-4.8.0.7z GOTO instMingW32
		%instdir%\msys\1.0\bin\wget.exe -c -O mingw32-gcc-4.8.0.7z "http://downloads.sourceforge.net/project/mingw-w64/Toolchains targetting Win32/Personal Builds/rubenvb/gcc-4.8-release/i686-w64-mingw32-gcc-4.8.0-win32_rubenvb.7z"

		:instMingW32
		%instdir%\opt\bin\7za.exe x mingw32-gcc-4.8.0.7z
		%instdir%\msys\1.0\bin\cp %instdir%\mingw32\bin\gcc.exe %instdir%\mingw32\bin\cc.exe
		del mingw32-gcc-4.8.0.7z
		ren %instdir%\mingw32\lib\libstdc++.dll.a libstdc++.dll.a.old
		)
		
:mingw64
if %build64%==yes (
if exist "%instdir%\mingw64\bin\gcc.exe" GOTO makeDIR
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install mingw 64bit compiler to mingw64
	echo.
	echo -------------------------------------------------------------------------------
	if exist mingw64-gcc-4.8.0.7z GOTO instMingW64
	%instdir%\msys\1.0\bin\wget.exe -c -O mingw64-gcc-4.8.0.7z "http://downloads.sourceforge.net/project/mingw-w64/Toolchains targetting Win64/Personal Builds/rubenvb/gcc-4.8-release/x86_64-w64-mingw32-gcc-4.8.0-win64_rubenvb.7z"
	
	:instMingW64
	%instdir%\opt\bin\7za.exe x mingw64-gcc-4.8.0.7z
	%instdir%\msys\1.0\bin\cp %instdir%\mingw64\bin\gcc.exe %instdir%\mingw64\bin\cc.exe
	del mingw64-gcc-4.8.0.7z
	ren %instdir%\mingw64\lib\libstdc++.dll.a libstdc++.dll.a.old
	)

:makeDIR
set targetSys=false
if exist %instdir%\local32\share set targetSys=true 
if exist %instdir%\local64\share set targetSys=true 
if %targetSys%==true GOTO writeConfFile
	echo -------------------------------------------------------------------------------
	echo.
	echo.- making build folders
	echo.
	echo -------------------------------------------------------------------------------
	if %build32%==yes (
		mkdir %instdir%\build32
		mkdir %instdir%\local32
		mkdir %instdir%\local32\bin
		mkdir %instdir%\local32\etc
		mkdir %instdir%\local32\include
		mkdir %instdir%\local32\lib
		mkdir %instdir%\local32\lib\pkgconfig
		mkdir %instdir%\local32\share
		)
	if %build64%==yes (
		mkdir %instdir%\build64
		mkdir %instdir%\local64
		mkdir %instdir%\local64\bin
		mkdir %instdir%\local64\etc
		mkdir %instdir%\local64\include
		mkdir %instdir%\local64\lib
		mkdir %instdir%\local64\lib\pkgconfig
		mkdir %instdir%\local64\share
		)
	
:writeConfFile
if exist %instdir%\conf-env.sh GOTO runConfFile
if exist %instdir%\msys\1.0\etc\userconf.cfg GOTO writeProfile32
	echo mount '%instdir%\opt\' /opt>>%instdir%\conf-env.sh
	echo mount '%instdir%\local32\' /local32>>%instdir%\conf-env.sh
	echo mount '%instdir%\build32\' /build32>>%instdir%\conf-env.sh
	echo mount '%instdir%\mingw32\' /mingw32>>%instdir%\conf-env.sh
	echo mount '%instdir%\local64\' /local64>>%instdir%\conf-env.sh
	echo mount '%instdir%\build64\' /build64>>%instdir%\conf-env.sh
	echo mount '%instdir%\mingw64\' /mingw64>>%instdir%\conf-env.sh

:runConfFile
if exist %instdir%\msys\1.0\etc\userconf.cfg GOTO writeProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- mounting build folders
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\sh -l %instdir%\conf-env.sh
	echo new mount done. see in fstap>> %instdir%\msys\1.0\etc\userconf.cfg
	del %instdir%\conf-env.sh

::------------------------------------------------------------------
:: write config profiles:
::------------------------------------------------------------------	

:writeProfile32
if %build32%==yes (
	if exist %instdir%\local32\etc\profile.local GOTO writeProfile64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- write profile for 32 bit compiling
		echo.
		echo -------------------------------------------------------------------------------
		echo.#>>%instdir%\local32\etc\profile.local
		echo.# /local32/etc/profile.local>>%instdir%\local32\etc\profile.local
		echo.#>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\local32\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PKG_CONFIG_PATH="/local32/lib/pkgconfig">>%instdir%\local32\etc\profile.local
		echo.CPPFLAGS="-I/local32/include">>%instdir%\local32\etc\profile.local
		echo.CFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.CXXFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.LDFLAGS="-L/local32/lib -mthreads">>%instdir%\local32\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PATH=".:/local32/bin:/mingw32/bin:/mingw/bin:/bin:/opt/bin">>%instdir%\local32\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local32\etc\profile.local
		echo.export PATH PS1>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.# package build directory>>%instdir%\local32\etc\profile.local
		echo.LOCALBUILDDIR=/build32>>%instdir%\local32\etc\profile.local
		echo.# package installation prefix>>%instdir%\local32\etc\profile.local
		echo.LOCALDESTDIR=/local32>>%instdir%\local32\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local32\etc\profile.local
		)
		
:writeProfile64
if %build64%==yes (
	if exist %instdir%\local64\etc\profile.local GOTO loginProfile
		echo -------------------------------------------------------------------------------
		echo.
		echo.- write profile for 64 bit compiling
		echo.
		echo -------------------------------------------------------------------------------
		echo.#>>%instdir%\local64\etc\profile.local
		echo.# /local64/etc/profile.local>>%instdir%\local64\etc\profile.local
		echo.#>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\local64\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PKG_CONFIG_PATH="/local64/lib/pkgconfig">>%instdir%\local64\etc\profile.local
		echo.CPPFLAGS="-I/local64/include">>%instdir%\local64\etc\profile.local
		echo.CFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.CXXFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.LDFLAGS="-L/local64/lib">>%instdir%\local64\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PATH=".:/local64/bin:/mingw64/bin:/mingw/bin:/bin:/opt/bin">>%instdir%\local64\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local64\etc\profile.local
		echo.export PATH PS1>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.# package build directory>>%instdir%\local64\etc\profile.local
		echo.LOCALBUILDDIR=/build64>>%instdir%\local64\etc\profile.local
		echo.# package installation prefix>>%instdir%\local64\etc\profile.local
		echo.LOCALDESTDIR=/local64>>%instdir%\local64\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local64\etc\profile.local
		)
	
:loginProfile
if exist %instdir%\msys\1.0\etc\userprofile.cfg GOTO extraPacks

if %build64%==yes (
	if %build32%==yes GOTO loginProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile (64 bit)
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /local64/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local64/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys\1.0\bin\sh -l %instdir%\profile.sh
	echo 64 bit build system add to profile. see profile>>%instdir%\msys\1.0\etc\userprofile.cfg
	del %instdir%\profile.sh
	GOTO extraPacks
	)
	
:loginProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile (32 bit)
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /local32/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local32/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys\1.0\bin\sh -l %instdir%\profile.sh
	echo 32 bit build system add to profile. see profile>>%instdir%\msys\1.0\etc\userprofile.cfg
	del %instdir%\profile.sh

:extraPacks
::------------------------------------------------------------------
:: get extra packs and compile global tools:
::------------------------------------------------------------------

if exist %instdir%\opt\bin\cmake.exe GOTO checkDoxygen32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- download and install extra packs
	echo.
	echo -------------------------------------------------------------------------------

	echo.cd ${LOCALBUILDDIR}>>%instdir%\extraPack.sh
	echo.wget -c "http://msysgit.googlecode.com/files/PortableGit-1.8.3-preview20130601.7z">>%instdir%\extraPack.sh
	echo.cd /opt>>%instdir%\extraPack.sh
	echo.7za x ${LOCALBUILDDIR}/PortableGit-1.8.3-preview20130601.7z>>%instdir%\extraPack.sh
	echo.rm git-bash.bat git-cmd.bat 'Git Bash.vbs'>>%instdir%\extraPack.sh
	echo.mv ReleaseNotes.rtf README.portable doc/git>>%instdir%\extraPack.sh
	echo.>>%instdir%\extraPack.sh
	
	echo.cd ${LOCALBUILDDIR}>>%instdir%\extraPack.sh
	echo.wget -c "http://downloads.sourceforge.net/project/win32svn/1.8.3/apache22/svn-win32-1.8.3.zip">>%instdir%\extraPack.sh
	echo.unzip svn-win32-1.8.3.zip>>%instdir%\extraPack.sh
	echo.cp -va svn-win32-1.8.3/* /opt>>%instdir%\extraPack.sh
	echo.mkdir -p /opt/doc/svn-win32-1.8.3>>%instdir%\extraPack.sh
	echo.mv /opt/README.txt /opt/doc/svn-win32-1.8.3>>%instdir%\extraPack.sh
	echo.>>%instdir%\extraPack.sh
	
	echo.cd ${LOCALBUILDDIR}>>%instdir%\extraPack.sh
	echo.wget -c "http://www.cmake.org/files/v2.8/cmake-2.8.11.1-win32-x86.zip">>%instdir%\extraPack.sh
	echo.unzip cmake-2.8.11.1-win32-x86.zip>>%instdir%\extraPack.sh
	echo.cp -va cmake-2.8.11.1-win32-x86/* /opt>>%instdir%\extraPack.sh
		
	echo.rm ${LOCALBUILDDIR}/PortableGit-1.8.3-preview20130601.7z>>%instdir%\extraPack.sh
	echo.rm ${LOCALBUILDDIR}/svn-win32-1.8.3.zip>>%instdir%\extraPack.sh
	echo.rm ${LOCALBUILDDIR}/cmake-2.8.11.1-win32-x86.zip>>%instdir%\extraPack.sh
	echo.rm -r ${LOCALBUILDDIR}/svn-win32-1.8.3>>%instdir%\extraPack.sh
	echo.rm -r ${LOCALBUILDDIR}/cmake-2.8.11.1-win32-x86>>%instdir%\extraPack.sh

	%instdir%\msys\1.0\bin\sh -l %instdir%\extraPack.sh
	del %instdir%\extraPack.sh
	
:checkDoxygen32	
if %build32%==yes (
	if exist %instdir%\mingw32\bin\doxygen.exe GOTO checkDoxygen64
	cd %instdir%\build32
	%instdir%\msys\1.0\bin\wget -c "http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.5.windows.bin.zip"
	cd %instdir%\mingw32\bin
	%instdir%\opt\bin\7za x %instdir%\build32\doxygen-1.8.5.windows.bin.zip
	del %instdir%\build32\doxygen-1.8.5.windows.bin.zip
	)
	
:checkDoxygen64
if %build64%==yes (
	if exist %instdir%\mingw64\bin\doxygen.exe GOTO checkYasm32
	cd %instdir%\build64
	%instdir%\msys\1.0\bin\wget -c "http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.5.windows.x64.bin.zip"
	cd %instdir%\mingw64\bin
	%instdir%\opt\bin\7za x %instdir%\build64\doxygen-1.8.5.windows.x64.bin.zip
	del %instdir%\build64\doxygen-1.8.5.windows.x64.bin.zip
	)
	
:checkYasm32	
if %build32%==yes (
	if exist %instdir%\mingw32\bin\yasm.exe GOTO checkYasm64
	cd %instdir%\build32
	%instdir%\msys\1.0\bin\wget -c "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0-win32.exe"
	ren yasm-1.2.0-win32.exe yasm.exe
	copy yasm.exe %instdir%\mingw32\bin
	del yasm.exe
	)	
	
:checkYasm64	
if %build64%==yes (
	if exist %instdir%\mingw64\bin\yasm.exe GOTO getMintty
	cd %instdir%\build64
	%instdir%\msys\1.0\bin\wget -c "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0-win64.exe"
	ren yasm-1.2.0-win64.exe yasm.exe
	copy yasm.exe %instdir%\mingw64\bin
	del yasm.exe
	)	
cd %instdir%

:getMintty
if exist %instdir%\msys\1.0\bin\mintty.exe GOTO minttySettings
	echo -------------------------------------------------------------------------------
	echo.
	echo.- download and install mintty (a nice shell console tool):
	echo. (it is recommended to don't use the windows cmd, it is not stable)
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\wget -c http://blog.pixelcrusher.de/downloads/media-autobuild_suite/mintty-1.1.3-msys.zip
	%instdir%\opt\bin\7za.exe e -r -y %instdir%\mintty-1.1.3-msys.zip -o%instdir%\msys\1.0\bin mintty.exe
	%instdir%\opt\bin\7za.exe e -r -y %instdir%\mintty-1.1.3-msys.zip -o%instdir%\msys\1.0\share\doc readme-msys.html
	
	for /f %%i in ('dir %instdir%\msys\1.0\home /B') do set userFolder=%%i
	
	echo.Set Shell = CreateObject^("WScript.Shell"^)>>%instdir%\setlink.vbs
	echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)>>%instdir%\setlink.vbs
	echo.link.Arguments = "/bin/sh -l" >>%instdir%\setlink.vbs
	echo.link.Description = "msys shell console">>%instdir%\setlink.vbs
	echo.link.TargetPath = "%instdir%\msys\1.0\bin\mintty.exe">>%instdir%\setlink.vbs
	echo.link.WindowStyle = ^1>>%instdir%\setlink.vbs
	echo.link.WorkingDirectory = "%instdir%\msys\1.0\bin">>%instdir%\setlink.vbs
	echo.link.Save>>%instdir%\setlink.vbs

	cscript /nologo %instdir%\setlink.vbs 
	del %instdir%\mintty-1.1.3-msys.zip 
	del %instdir%\setlink.vbs 
	
::mintty seetings, color, transparency, etc.
:minttySettings
if exist %instdir%\msys\1.0\home\%userFolder%\.minttyrc GOTO compileGlobals32
	echo.BoldAsFont=no>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BackgroundColour=57,57,57>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.ForegroundColour=221,221,221>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Transparency=medium>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.FontHeight=^9>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.FontSmoothing=full>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.AllowBlinking=yes>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Font=DejaVu Sans Mono>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Columns=90>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Rows=30>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Locale=de_DE>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Charset=ISO-8859-1>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Term=xterm-256color>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.CursorType=block>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Black=38,39,41>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Red=249,38,113>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Green=166,226,46>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Yellow=253,151,31>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Blue=102,217,239>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Magenta=158,111,254>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Cyan=94,113,117>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.White=248,248,242>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldBlack=85,68,68>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldRed=249,38,113>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldGreen=166,226,46>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldYellow=253,151,31>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldBlue=102,217,239>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldMagenta=158,111,254>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldCyan=163,186,191>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldWhite=248,248,242>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc

:compileGlobals32
:: no existing check here, because it is more easy to extend the global tools. 
:: existing check in compileGlobals32.sh/compileGlobals64.sh
if %build32%==yes (
	if exist %instdir%\compileGlobals32.sh GOTO compileGobal32
		echo -------------------------------------------------------------------------------
		echo.
		echo.- download global tools, 32 bit
		echo.
		echo -------------------------------------------------------------------------------
		if exist %instdir%\media-autobuild_suite.zip GOTO unpackglobal32
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
			
			:unpackglobal32
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compileGlobals32.sh

	:compileGobal32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile global tools, 32 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compileGlobals32.sh --cpuCount=%cpuCount%
	)

::compileGlobals64
if %build64%==yes (
	if exist %instdir%\compileGlobals32.sh GOTO compileGobal64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- download global tools, 64 bit
		echo.
		echo -------------------------------------------------------------------------------
		if exist %instdir%\media-autobuild_suite.zip GOTO unpackglobal64
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
			
			:unpackglobal64
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compileGlobals64.sh

	:compileGobal64
	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile global tools, 64 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compileGlobals64.sh --cpuCount=%cpuCount%
	)

:: audio coder
:getAudio32
if %build32%==yes (
	if exist %instdir%\compile_audiotools32.sh GOTO compileAudio32
		echo -------------------------------------------------------------------------------
		echo.
		echo.- get script for audio coder, 32 bit:
		echo.
		echo -------------------------------------------------------------------------------
		if exist %instdir%\media-autobuild_suite.zip GOTO unpackAudio32
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
		
			:unpackAudio32
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_audiotools32.sh
	
	:compileAudio32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile audio coder, 32 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compile_audiotools32.sh --cpuCount=%cpuCount% --nonfree=%binary%
	echo. compile audio coder 32 bit done...
	)
	
:getAudio64
if %build64%==yes (
	if exist %instdir%\compile_audiotools64.sh GOTO compileAudio64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- get script for audio coder, 64 bit:
		echo.
		echo -------------------------------------------------------------------------------
		if exist %instdir%\media-autobuild_suite.zip GOTO unpackAudio64
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
			
			:unpackAudio64
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_audiotools64.sh
	
	:compileAudio64
	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile audio coder, 64 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compile_audiotools64.sh --cpuCount=%cpuCount% --nonfree=%binary%
	echo. compile audio coder 64 bit done...
	)	

:: video coder
if %build32%==yes (
	if not exist %instdir%\compile_videotools32.sh (
		echo -------------------------------------------------------------------------------
		echo.
		echo.- get script for video coder, 32 bit:
		echo.
		echo -------------------------------------------------------------------------------
		if not exist %instdir%\media-autobuild_suite.zip (
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
			)
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_videotools32.sh
		)

	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile video coder, 32 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compile_videotools32.sh --cpuCount=%cpuCount% --mp4box=%mp4box% --mplayer=%mplayer% --nonfree=%binary%
	echo. compile video coder 32 bit done...
	)

if %build64%==yes (
	if not exist %instdir%\compile_videotools64.sh (
		echo -------------------------------------------------------------------------------
		echo.
		echo.- get script for video coder, 64 bit:
		echo.
		echo -------------------------------------------------------------------------------
		if not exist %instdir%\media-autobuild_suite.zip (
			%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
			)
			%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_videotools64.sh
		)	
	
	:compileVideo64
	echo -------------------------------------------------------------------------------
	echo.
	echo.- compile video coder, 64 bit:
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\mintty.lnk %instdir%\compile_videotools64.sh --cpuCount=%cpuCount% --mp4box=%mp4box% --mplayer=%mplayer% --nonfree=%binary%
	echo. compile video coder 64 bit done...
	)

:: ffmpeg
if %ffmpeg%==y (
	if %build32%==yes (
		if not exist %instdir%\compile_ffmpeg32.sh (
			echo -------------------------------------------------------------------------------
			echo.
			echo.- get script for ffmpeg, 32 bit:
			echo.
			echo -------------------------------------------------------------------------------
			if not exist %instdir%\media-autobuild_suite.zip (
				%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
				)
				%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_ffmpeg32.sh
			)

		echo -------------------------------------------------------------------------------
		echo.
		echo.- compile ffmpeg, 32 bit:
		echo.
		echo -------------------------------------------------------------------------------
		%instdir%\mintty.lnk %instdir%\compile_ffmpeg32.sh --cpuCount=%cpuCount% --nonfree=%binary%
		echo. compile ffmpeg 32 bit done...
		)

	if %build64%==yes (
		if not exist %instdir%\compile_ffmpeg64.sh (
			echo -------------------------------------------------------------------------------
			echo.
			echo.- get script for ffmpeg, 64 bit:
			echo.
			echo -------------------------------------------------------------------------------
			if not exist %instdir%\media-autobuild_suite.zip (
				%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
				)
				%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_ffmpeg64.sh
			)

		:compileFFmpeg64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- compile ffmpeg, 64 bit:
		echo.
		echo -------------------------------------------------------------------------------
		%instdir%\mintty.lnk %instdir%\compile_ffmpeg64.sh --cpuCount=%cpuCount% --nonfree=%binary%
		echo. compile ffmpeg 64 bit done...
		)
	)
	
::imagemagick	
if %magick%==y (
	if %build32%==yes (
		if not exist %instdir%\compile_imagemagick32.sh (
			echo -------------------------------------------------------------------------------
			echo.
			echo.- get script for imagemagick, 32 bit:
			echo.
			echo -------------------------------------------------------------------------------
			if not exist %instdir%\media-autobuild_suite.zip (
				%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
				)
				%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_imagemagick32.sh
			)

		echo -------------------------------------------------------------------------------
		echo.
		echo.- compile imagemagick, 32 bit:
		echo.
		echo -------------------------------------------------------------------------------
		%instdir%\mintty.lnk %instdir%\compile_imagemagick32.sh --cpuCount=%cpuCount%
		echo. compile imagemagick 32 bit done...
		)
	
	if %build64%==yes (
		if not exist %instdir%\compile_imagemagick64.sh (
			echo -------------------------------------------------------------------------------
			echo.
			echo.- get script for imagemagick, 64 bit:
			echo.
			echo -------------------------------------------------------------------------------
			if not exist %instdir%\media-autobuild_suite.zip (
				%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
				)
				%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_imagemagick64.sh
			)

		echo -------------------------------------------------------------------------------
		echo.
		echo.- compile imagemagick, 64 bit:
		echo.
		echo -------------------------------------------------------------------------------
		%instdir%\mintty.lnk %instdir%\compile_imagemagick64.sh --cpuCount=%cpuCount%
		echo. compile imagemagick 64 bit done...
		)
	)
	
	
echo -------------------------------------------------------------------------------
echo.
echo. compiling done...
echo.
echo -------------------------------------------------------------------------------

ping 127.0.0.0 -n 3 >nul
echo.
echo Window close in 15
echo.
ping 127.0.0.0 -n 5 >nul
echo.
echo Window close in 10
echo.
ping 127.0.0.0 -n 5 >nul
echo.
echo Window close in 5
echo.
ping 127.0.0.0 -n 5 >nul
echo.