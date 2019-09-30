#!/bin/bash
export LANG=en_US.UTF-8
export DISPLAY=:99
export XDG_RUNTIME_DIR=${DATA_DIR}/.cache/runtime-rpd/

echo "---Checking if Rapid Photo Downloader is installed---"
if [ "${FORCE_UPDATE}" == "true" ]; then
	echo "--------------------------------------------"
	echo "---Force Update set to 'true' please wait---"
	echo "---------This can takes some time-----------"
	echo "--------depending on your hardware----------"
	echo "--------------------------------------------"
    sleep 10
    cd ${DATA_DIR}
	if [ -f "${DATA_DIR}/install.py" ]; then
    	rm ${DATA_DIR}/install.py
    fi
    wget "${DL_URL}"
	if [ ! -f "${DATA_DIR}/install.py" ]; then
		echo "---------------------------------------------"
		echo "---Something went wrong, couldn't download---"
		echo "---'install.py' please check the download----"
		echo "---link or place the file manually in the----"
		echo "----------root of your serverfolder----------"
		echo "---------------------------------------------"
		sleep infinity
	fi
	python3 -m venv ${DATA_DIR}/rpd
	source ${DATA_DIR}/rpd/bin/activate
	python3 install.py --virtual-env
	deactivate
else
	if [ ! -f "${DATA_DIR}/rpd/bin/rapid-photo-downloader" ]; then
		echo "--------------------------------------"
		echo "---Rapid Photo Downloader not found---"
    	echo "-------This can takes some time-------"
    	echo "------depending on your hardware------"
    	echo "--------------------------------------"
        sleep 10
		cd ${DATA_DIR}
		if [ ! -f "${DATA_DIR}/install.py" ]; then
			wget "${DL_URL}"
            if [ ! -f "${DATA_DIR}/install.py" ]; then
            	echo "---------------------------------------------"
            	echo "---Something went wrong, couldn't download---"
            	echo "---'install.py' please check the download----"
            	echo "---link or place the file manually in the----"
            	echo "----------root of your serverfolder----------"
            	echo "---------------------------------------------"
            	sleep infinity
            fi
		fi
		python3 -m venv ${DATA_DIR}/rpd
		source ${DATA_DIR}/rpd/bin/activate
		python3 install.py --virtual-env
		deactivate
	else
		echo "---Rapid Photo Downloader found---"
	fi
fi

echo "---Preparing directories---"
if [ ! -d "${DATA_DIR}/.cache/runtime-rpd" ]; then
	if [ ! -d "${DATA_DIR}/.cache" ]; then
    	mkdir ${DATA_DIR}/.cache
    fi
	mkdir ${DATA_DIR}/.cache/runtime-rpd
fi

if [ ! -d "${DATA_DIR}/.config/Rapid Photo Downloader" ]; then
	if [ ! -d "${DATA_DIR}/.config" ]; then
    	mkdir ${DATA_DIR}/.config
    fi
    mkdir "${DATA_DIR}/.config/Rapid Photo Downloader"
fi

if [ ! -f "${DATA_DIR}/.config/Rapid Photo Downloader/Rapid Photo Downloader.conf" ]; then
    cd "${DATA_DIR}/.config/Rapid Photo Downloader/"
    touch "Rapid Photo Downloader.conf"
	echo "[MainWindow]
windowPosition=@Point(0 0)
windowSize=@Size(1024 881)" >> "${DATA_DIR}/.config/Rapid Photo Downloader/Rapid Photo Downloader.conf"
fi

echo "---Preparing Server---"
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old lock files---"
find /tmp -name ".X99*" -exec rm -f {} \;
find /var/run/dbus -name "pid" -exec rm -f {} \;
chmod -R 770 ${DATA_DIR}

echo "---Starting dbus service---"
if dbus-daemon --config-file=/usr/share/dbus-1/system.conf ; then
	echo "---dbus service started---"
else
	echo "---Couldn't start dbus service---"
	sleep infinity
fi
sleep 5

echo "---Starting Xvfb server---"
screen -S Xvfb -L -Logfile ${DATA_DIR}/XvfbLog.0 -d -m /opt/scripts/start-Xvfb.sh
sleep 5

echo "---Starting x11vnc server---"
screen -S x11vnc -L -Logfile ${DATA_DIR}/x11vncLog.0 -d -m /opt/scripts/start-x11.sh
sleep 5

echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem 8080 localhost:5900
sleep 5

echo "---Starting Rapid Photo Downloader---"
cd ${DATA_DIR}/rpd/bin
until ./rapid-photo-downloader; do
	echo "Rapid Photo Downloader crashed with exit code $?.  Respawning.." >&2
	sleep 1
done