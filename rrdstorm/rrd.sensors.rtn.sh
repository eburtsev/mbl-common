#!/bin/sh

# data definition: Average system load
UT=$(head -n1 /proc/loadavg)
L1=$(echo "$UT"|awk "{print \$1}")
L5=$(echo "$UT"|awk "{print \$2}")
L15=$(echo "$UT"|awk "{print \$3}")
echo "${L1}:${L5}:${L15}"

# data definition: RAM usage
C=$(grep ^Cached /proc/meminfo|awk "{print \$2}")
B=$(grep ^Buffers /proc/meminfo|awk "{print \$2}")
F=$(grep ^MemFree /proc/meminfo|awk "{print \$2}")
T=$(grep ^MemTotal /proc/meminfo|awk "{print \$2}")
ST=$(grep ^SwapTotal /proc/meminfo|awk "{print \$2}")
SF=$(grep ^SwapFree /proc/meminfo|awk "{print \$2}")
echo "${C}:${B}:${F}:${T}:${ST}:${SF}"

# data definition: Wireless PHY's temperatures
TEMP_24=$(/usr/sbin/wl -i eth1 phy_tempsense)
TEMP_50=$(/usr/sbin/wl -i eth2 phy_tempsense)

if [ -z "$TEMP_24" ]; then
 TEMP_24=0
else
 TEMP_24=$(($(echo "$TEMP_24" | awk "{print \$1}") /2 + 20))
fi

if [ -z "$TEMP_50" ]; then
 TEMP_50=0
else
 TEMP_50=$(($(echo "$TEMP_50" | awk "{print \$1}") /2 + 20))
fi
echo "${TEMP_24}:${TEMP_50}"

# data definition: CPU usage
cat /proc/stat|head -1|sed "s/^cpu\ \+\([0-9]*\)\ \([0-9]*\)\ \([0-9]*\)\ \([0-9]*\).*/\1:\2:\3:\4/"

# data definition: WAN traffic statistics
IF="ppp0"
IN=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$1}")
OUT=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${IN}:${OUT}"

# data definition: Disk space
SP=$(/opt/bin/df "-B1")
echo -n $(echo "$SP"|grep SDCARD|awk "{print \$4\":\"\$3}"):
echo -n $(echo "$SP"|grep USB4GB|awk "{print \$4\":\"\$3}")
echo

# data definition: Wireless outgoing traffic
OUT_24=$(grep eth1 /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
OUT_50=$(grep eth2 /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${OUT_24}:${OUT_50}"

#data definition: UPS
DUMP=$(/opt/sbin/apcaccess)
LINEV=$(echo "$DUMP" | grep "^LINEV" | awk "{print \$3}")
#OUTPUTV=$(echo "$DUMP" | grep "^OUTPUTV" | awk "{print \$3}")
LOADPCT=$(echo "$DUMP" | grep "^LOADPCT" | awk "{print \$3}")
TIMELEFT=$(echo "$DUMP" | grep "^TIMELEFT" | awk "{print \$3}")
ITEMP=$(echo "$DUMP" | grep "^ITEMP" | awk "{print \$3}")
echo  "${LINEV}" | sed 's/\.[0-9]$//'
#echo ":${OUTPUTV}" | sed 's/\.[0-9]$//'
echo "${LOADPCT}" | sed 's/\.[0-9]$//'
echo "${TIMELEFT}" | sed 's/\.[0-9]$//'
echo "${ITEMP}" | sed 's/\.[0-9]$//'
