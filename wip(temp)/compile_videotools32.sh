source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--vlc=* ) vlc="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

if [[ $nonfree = "y" ]]; then
    faac=""
  else
    if  [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc" 
	fi
fi	

# check if compiled file exist
do_checkIfExist() {
	local packetName="$1"
	local fileName="$2"
	local fileExtension=${fileName##*.}
	if [[ "$fileExtension" = "exe" ]]; then
		if [ -f "$LOCALDESTDIR/bin/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]]; then
		if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	fi
}
echo "-------------------------------------------------------------------------------"
echo 
echo "compile video tools 32 bit"
echo 
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "x264-git/configure" ]; then
	echo -ne "\033]0;compiling x264 32Bit\007"
	cd x264-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		rm $LOCALDESTDIR/bin/x264-10bit.exe
		make uninstall
		make clean
		./configure --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread
		make -j $cpuCount
		make install
		make clean

		./configure --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
		
		do_checkIfExist x264-git x264-10bit.exe
	else
		echo -------------------------------------------------
		echo "x264 is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compiling x264 32Bit\007"
		git clone http://repo.or.cz/r/x264.git x264-git
		cd x264-git
		./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread
		make -j $cpuCount
		make install
		make clean

		./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
		make clean
		
		do_checkIfExist x264-git x264-10bit.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxvidcore.a" ]; then
	echo -------------------------------------------------
	echo "xvidcore is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling xvidcore 32Bit\007"
		wget -c http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz
		tar xf xvidcore-1.3.2.tar.gz
		rm xvidcore-1.3.2.tar.gz
		cd xvidcore/build/generic
		./configure --prefix=$LOCALDESTDIR
		sed -i "s/-mno-cygwin//" platform.inc
		make -j $cpuCount
		make install

		if [[ -f "$LOCALDESTDIR/lib/xvidcore.dll" ]]; then
			rm $LOCALDESTDIR/lib/xvidcore.dll || exit 1
			mv $LOCALDESTDIR/lib/xvidcore.a $LOCALDESTDIR/lib/libxvidcore.a || exit 1
		fi
		
		do_checkIfExist xvidcore libxvidcore.a
fi

cd $LOCALBUILDDIR

if [ -f "libvpx-git/configure" ]; then
	echo -ne "\033]0;compiling libvpx 32Bit\007"
	cd libvpx-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
	if [ -d "$LOCALDESTDIR/include/vpx" ]; then rm -r $LOCALDESTDIR/include/vpx; fi
	if [ -f "$LOCALDESTDIR/lib/pkgconfig/vpx.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/vpx.pc; fi
	if [ -f "$LOCALDESTDIR/lib/libvpx.a" ]; then rm $LOCALDESTDIR/lib/libvpx.a; fi
		make clean
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
        make -j $cpuCount
        make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
		do_checkIfExist libvpx-git libvpx.a
	else
		echo -------------------------------------------------
		echo "libvpx-git is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compiling libvpx 32Bit\007"
		git clone http://git.chromium.org/webm/libvpx.git libvpx-git
		cd libvpx-git
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
		make -j $cpuCount
		make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
		do_checkIfExist libvpx-git libvpx.a
fi

cd $LOCALBUILDDIR
		
if [ -f "libbluray-git/bootstrap" ]; then
	echo -ne "\033]0;compiling libbluray 32Bit\007"
	cd libbluray-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		make uninstall
		make clean
		/bootstrap
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist libbluray-git libbluray.a
	else
		echo -------------------------------------------------
		echo "libbluray is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compiling libbluray 32Bit\007"
		git clone git://git.videolan.org/libbluray.git libbluray-git
		cd libbluray-git
		./bootstrap
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install

		do_checkIfExist libbluray-git libbluray.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libutvideo.a" ]; then
	echo -------------------------------------------------
	echo "libutvideo is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libutvideo 32Bit\007"
		git clone git://github.com/qyot27/libutvideo.git libutvideo-git
		cd libutvideo-git
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install

		do_checkIfExist libutvideo-git libutvideo.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
	echo -------------------------------------------------
	echo "xavs is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling xavs 32Bit\007"
		svn checkout --trust-server-cert https://svn.code.sf.net/p/xavs/code/trunk/ xavs
		cd xavs
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		
		do_checkIfExist xavs libxavs.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdvdcss.a" ]; then
	echo -------------------------------------------------
	echo "libdvdcss-1.2.13 is already compiled"
	echo -------------------------------------------------
	else 
			echo -ne "\033]0;compiling libdvdcss 32Bit\007"
			wget -c http://download.videolan.org/pub/videolan/libdvdcss/1.2.13/libdvdcss-1.2.13.tar.bz2
			tar xf libdvdcss-1.2.13.tar.bz2
			rm libdvdcss-1.2.13.tar.bz2
			cd libdvdcss-1.2.13
			./configure --prefix=$LOCALDESTDIR --disable-shared
			make -j $cpuCount
			make install
			
			do_checkIfExist libdvdcss-1.2.13 libdvdcss.a
fi

cd $LOCALBUILDDIR

if [ -f "libdvdread-4.2.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "libdvdread-4.2.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libdvdread 32Bit\007"
		wget -c http://dvdnav.mplayerhq.hu/releases/libdvdread-4.2.1-rc1.tar.xz
		tar xf libdvdread-4.2.1-rc1.tar.xz
		rm libdvdread-4.2.1-rc1.tar.xz
		cd libdvdread-4.2.1
		if [[ ! -f ./configure ]]; then
			./autogen.sh
		fi	
		./configure --prefix=$LOCALDESTDIR --disable-shared CFLAGS="-I$LOCALDESTDIR/include -mms-bitfields -mthreads -mtune=pentium3 -DHAVE_DVDCSS_DVDCSS_H" LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -ldvdcss"
		sed -i 's/#define ATTRIBUTE_PACKED __attribute__ ((packed))/#define ATTRIBUTE_PACKED __attribute__ ((packed,gcc_struct))/' src/dvdread/ifo_types.h
		make -j $cpuCount
		make install
		sed -i "s/-ldvdread.*/-ldvdread -ldvdcss -ldl/" $LOCALDESTDIR/bin/dvdread-config
		sed -i 's/-ldvdread.*/-ldvdread -ldvdcss -ldl/' "$PKG_CONFIG_PATH/dvdread.pc"
		
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libdvdread.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libdvdread-4.2.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libdvdread-4.2.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libdvdnav-4.2.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "libdvdnav-4.2.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libdvdnav 32Bit\007"
		wget -c http://dvdnav.mplayerhq.hu/releases/libdvdnav-4.2.1-rc1.tar.xz
		tar xf libdvdnav-4.2.1-rc1.tar.xz
		rm libdvdnav-4.2.1-rc1.tar.xz
		cd libdvdnav-4.2.1
		if [[ ! -f ./configure ]]; then
			./autogen.sh
		fi
		./configure --prefix=$LOCALDESTDIR --disable-shared --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config
		make -j $cpuCount
		make install
		sed -i "s/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread -ldl/" $LOCALDESTDIR/bin/dvdnav-config
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libdvdnav.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libdvdnav-4.2.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libdvdnav-4.2.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libmpeg2-0.5.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "libmpeg2-0.5.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libmpeg2 32Bit\007"
		wget -c http://libmpeg2.sourceforge.net/files/libmpeg2-0.5.1.tar.gz
		tar xf libmpeg2-0.5.1.tar.gz
		rm libmpeg2-0.5.1.tar.gz
		cd libmpeg2-0.5.1
		./configure --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libmpeg2.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libmpeg2-0.5.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libmpeg2-0.5.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

#------------------------------------------------
# final tools
#------------------------------------------------

cd $LOCALBUILDDIR

if [[ $mp4box = "y" ]]; then
	if [ -f "mp4box_gpac/compile.done" ]; then
		echo -------------------------------------------------
		echo "mp4box_gpac is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compiling mp4box_gpac 32Bit\007"
			svn co svn://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
			cd mp4box_gpac
			rm extra_lib/include/zlib/zconf.h
			rm extra_lib/include/zlib/zlib.h
			cp $LOCALDESTDIR/lib/libz.a extra_lib/lib/gcc
			cp $LOCALDESTDIR/include/zconf.h extra_lib/include/zlib
			cp $LOCALDESTDIR/include/zlib.h extra_lib/include/zlib
			./configure --static-mp4box --enable-static-bin --extra-libs=-lws2_32 -lwinmm --use-zlib=local --use-ffmpeg=no --use-png=no 
			cp config.h include/gpac/internal
			make -j $cpuCount
			cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin
			echo "finish" > compile.done
			
			if [ -f "$LOCALDESTDIR/bin/mp4box.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build mp4box done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build mp4box failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

cd $LOCALBUILDDIR

if [[ $ffmpeg = "y" ]]; then
	if [[ $nonfree = "y" ]]; then
		extras="--enable-nonfree --enable-libfaac --enable-libfdk-aac"
	  else
		if  [[ $nonfree = "n" ]]; then
		  extras="" 
		fi
	fi		

	echo "-------------------------------------------------------------------------------"
	echo 
	echo "compile ffmpeg 32 bit"
	echo 
	echo "-------------------------------------------------------------------------------"

	if [ -f "ffmpeg-git/configure" ]; then
		echo -ne "\033]0;compiling ffmpeg 32Bit\007"
		cd ffmpeg-git
		oldHead=`git rev-parse HEAD`
		git pull origin master
		newHead=`git rev-parse HEAD`
		if [[ "$oldHead" != "$newHead" ]]; then
			make uninstall
			make clean
			./configure --arch=x86 --prefix=$LOCALDESTDIR --extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lxml2 -lz -liconv -lws2_32' --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-libbluray --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid $extras
			make -j $cpuCount
			make install
			
			if [ -f "$LOCALDESTDIR/bin/ffmpeg.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build ffmpeg done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build ffmpeg failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
		else
			echo -------------------------------------------------
			echo "ffmpeg is already up to date"
			echo -------------------------------------------------
		fi
		else
			echo -ne "\033]0;compiling ffmpeg 32Bit\007"
			cd $LOCALBUILDDIR
			if [ -d "$LOCALDESTDIR/include/libavutil" ]; then rm -r $LOCALDESTDIR/include/libavutil; fi
			if [ -d "$LOCALDESTDIR/include/libavcodec" ]; then rm -r $LOCALDESTDIR/include/libavcodec; fi
			if [ -d "$LOCALDESTDIR/include/libpostproc" ]; then rm -r $LOCALDESTDIR/include/libpostproc; fi
			if [ -d "$LOCALDESTDIR/include/libswresample" ]; then rm -r $LOCALDESTDIR/include/libswresample; fi
			if [ -d "$LOCALDESTDIR/include/libswscale" ]; then rm -r $LOCALDESTDIR/include/libswscale; fi
			if [ -d "$LOCALDESTDIR/include/libavdevice" ]; then rm -r $LOCALDESTDIR/include/libavdevice; fi
			if [ -d "$LOCALDESTDIR/include/libavfilter" ]; then rm -r $LOCALDESTDIR/include/libavfilter; fi
			if [ -d "$LOCALDESTDIR/include/libavformat" ]; then rm -r $LOCALDESTDIR/include/libavformat; fi
			if [ -f "$LOCALDESTDIR/lib/libavutil.a" ]; then rm -r $LOCALDESTDIR/lib/libavutil.a; fi
			if [ -f "$LOCALDESTDIR/lib/libswresample.a" ]; then rm -r $LOCALDESTDIR/lib/libswresample.a; fi
			if [ -f "$LOCALDESTDIR/lib/libswscale.a" ]; then rm -r $LOCALDESTDIR/lib/libswscale.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then rm -r $LOCALDESTDIR/lib/libavcodec.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavdevice.a" ]; then rm -r $LOCALDESTDIR/lib/libavdevice.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavfilter.a" ]; then rm -r $LOCALDESTDIR/lib/libavfilter.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavformat.a" ]; then rm -r $LOCALDESTDIR/lib/libavformat.a; fi
			if [ -f "$LOCALDESTDIR/lib/libpostproc.a" ]; then rm -r $LOCALDESTDIR/lib/libpostproc.a; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavcodec.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavutil.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavutil.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libpostproc.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswresample.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libswresample.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswscale.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libswscale.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavdevice.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavfilter.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavformat.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavformat.pc; fi

			git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg-git
			cd ffmpeg-git
			./configure --arch=x86 --prefix=$LOCALDESTDIR --extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lxml2 -lz -liconv -lws2_32' --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-libbluray --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid $extras
			make -j $cpuCount
			make install
			
			if [ -f "$LOCALDESTDIR/bin/ffmpeg.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build ffmpeg done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build ffmpeg failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

cd $LOCALBUILDDIR

if [[ $mplayer = "y" ]]; then
	if [ -f mplayer-checkout*/compile.done ]; then
		echo -------------------------------------------------
		echo "mplayer is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compiling mplayer 32Bit\007"
			wget -c http://www.mplayerhq.hu/MPlayer/releases/mplayer-checkout-snapshot.tar.bz2
			tar xf mplayer-checkout-snapshot.tar.bz2
			cd mplayer-checkout*
			
			if ! test -e ffmpeg ; then
				if ! git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git ffmpeg ; then
					rm -rf ffmpeg
					echo "Failed to get a FFmpeg checkout"
					echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
					echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
					echo "To use a github mirror via http (e.g. because a firewall blocks git):"
					echo "git clone --depth 1 https://github.com/FFmpeg/FFmpeg ffmpeg; touch ffmpeg/mp_auto_pull"
					exit 1
				fi
				touch ffmpeg/mp_auto_pull
			fi
			./configure --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -O3' --enable-static --enable-runtime-cpudetection --disable-ass --enable-ass-internal --with-dvdnav-config=$LOCALDESTDIR/bin/dvdnav-config --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config --disable-dvdread-internal --disable-libdvdcss-internal $faac
			make
			make install
			echo "finish" > compile.done
			cd $LOCALBUILDDIR
			rm mplayer-checkout-snapshot.tar.bz2
			
			if [ -f "$LOCALDESTDIR/bin/mplayer.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build mplayer done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build mplayer failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

cd $LOCALBUILDDIR

if [[ $vlc = "y" ]]; then
	if [ -f "vlc-git/bootstrap" ]; then
		echo -ne "\033]0;compiling vlc 32Bit\007"
		cd vlc-git
		oldHead=`git rev-parse HEAD`
		git pull origin master
		newHead=`git rev-parse HEAD`
		if [[ "$oldHead" != "$newHead" ]]; then
		make clean
		if [[ ! -f "configure" ]]; then
			./bootstrap
		fi 
		./configure --disable-libgcrypt --host=i586-pc-mingw32msvc --enable-qt
		make -j $cpuCount
		
		sed -i "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
		sed -i "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
		for file in ./*/vlc.exe; do
			rm $file # try to force a rebuild...
		done
		make package-win-common
		strip --strip-all ./vlc-2.2.0-git/*.dll
		strip --strip-all ./vlc-2.2.0-git/*.exe
		cp -rf ./vlc-2.2.0-git $LOCALDESTDIR/bin
		
		if [ -f "$LOCALDESTDIR/bin/vlc-2.2.0-git/vlc.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build vlc done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build vlc failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
		else
			echo -------------------------------------------------
			echo "vlc is already up to date"
			echo -------------------------------------------------
		fi
		else
		echo -ne "\033]0;compiling vlc 32Bit\007"
			git clone https://github.com/videolan/vlc.git vlc-git
			cd vlc-git
			sed -i '/SYS=mingw32/ a\		CC="$CC -static-libgcc"' configure.ac
			sed -i '/		CC="$CC -static-libgcc"/ a\		CXX="$CXX -static-libgcc -static-libstdc++"' configure.ac
			sed -i 's/AC_DEFINE_UNQUOTED(VLC_COMPILE_HOST, "`hostname -f 2>\/dev\/null || hostname`", \[host which ran configure\])/AC_DEFINE_UNQUOTED(VLC_COMPILE_HOST, "`hostname`", \[host which ran configure\])/' configure.ac
			cp -v /usr/share/aclocal/* m4/
			if [[ ! -f "configure" ]]; then
				./bootstrap
			fi 
			./configure --disable-libgcrypt --host=i586-pc-mingw32msvc --enable-qt
			make -j $cpuCount
			
			sed -i "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
			sed -i "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
			for file in ./*/vlc.exe; do
				rm $file # try to force a rebuild...
			done
			make package-win-common
			strip --strip-all ./vlc-2.2.0-git/*.dll
			strip --strip-all ./vlc-2.2.0-git/*.exe
			cp -rf ./vlc-2.2.0-git $LOCALDESTDIR/bin
			
			if [ -f "$LOCALDESTDIR/bin/vlc-2.2.0-git/vlc.exe" ]; then
					echo -
					echo -------------------------------------------------
					echo "build vlc done..."
					echo -------------------------------------------------
					echo -
					else
						echo -------------------------------------------------
						echo "build vlc failed..."
						echo "delete the source folder under '$LOCALBUILDDIR' and start again"
						read -p "first close the batch window, then the shell window"
						sleep 15
				fi
	fi
fi

sleep 3