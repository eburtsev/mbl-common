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

# data definition: Disk temperature
/usr/sbin/smartctl --attributes /dev/sda | grep ^194 | awk "{print \$10}"

# data definition: CPU usage
cat /proc/stat|head -1|sed "s/^cpu\ \+\([0-9]*\)\ \([0-9]*\)\ \([0-9]*\)\ \([0-9]*\).*/\1:\2:\3:\4/"

# data definition: Ethernet traffic statistics
IF="eth0"
IN=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$1}")
OUT=$(grep "${IF}" /proc/net/dev|awk -F ":" "{print \$2}"|awk "{print \$9}")
echo "${IN}:${OUT}"

# data definition: Disk space
SP=$(/bin/df "-B1")
echo -n $(echo "$SP"|grep md0|awk "{print \$4\":\"\$3}"):
echo $(echo "$SP"|grep DataVolume|awk "{print \$4\":\"\$3}")

