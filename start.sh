#!/bin/bash
#$1 = SERVER_MEMORY
#$2 = MINECRAFT_VERSION

set -e

# --------------------------------------------------
# Memory Adjustment
# --------------------------------------------------

if [ "$1" -ge 10000 ]; then
    adjusted_memory=$(($1 - $1 * 10 / 100))
elif [ "$1" -ge 4000 ]; then
    adjusted_memory=$(($1 - $1 * 10 / 100))
elif [ "$1" -ge 2000 ]; then
    adjusted_memory=$(($1 - $1 * 15 / 100))
elif [ "$1" -ge 1000 ]; then
    adjusted_memory=$(($1 - $1 * 10 / 100))
else
    adjusted_memory=$(($1 - $1 * 5 / 100))
fi

if [ "$adjusted_memory" -lt 512 ]; then
    adjusted_memory=512
fi

echo "[PaperMC Updater] Adjusted server memory to ${adjusted_memory}MB"

USER_AGENT="Pterodactyl-Paper-Updater"

# --------------------------------------------------
# Resolve Minecraft Version
# --------------------------------------------------

if [ "$2" = "latest" ]; then
    VERSION=$(curl -s \
        -H "User-Agent: $USER_AGENT" \
        https://fill.papermc.io/v3/projects/paper/versions \
        | grep -o '"id":"[^"]*"' \
        | head -1 \
        | cut -d'"' -f4)
else
    VERSION="$2"
fi

echo "[PaperMC Updater] Using Minecraft version: $VERSION"

# --------------------------------------------------
# Resolve Latest Build
# --------------------------------------------------

BUILD=$(curl -s \
    -H "User-Agent: $USER_AGENT" \
    "https://fill.papermc.io/v3/projects/paper/versions/$VERSION/builds" \
    | grep -o '"id":[0-9]*' \
    | head -1 \
    | cut -d':' -f2)

echo "[PaperMC Updater] Latest build: $BUILD"

# --------------------------------------------------
# Resolve Download URL
# --------------------------------------------------

BUILD_INFO=$(curl -s \
    -H "User-Agent: $USER_AGENT" \
    "https://fill.papermc.io/v3/projects/paper/versions/$VERSION/builds/$BUILD")

DOWNLOAD_URL=$(echo "$BUILD_INFO" \
    | grep -o '"url":"[^"]*"' \
    | head -1 \
    | cut -d'"' -f4 \
    | sed 's/\\\//\//g')

echo "[PaperMC Updater] Download URL:"
echo "$DOWNLOAD_URL"

# --------------------------------------------------
# Download Paper
# --------------------------------------------------

mkdir -p "/home/container/paper/$VERSION"

JAR_PATH="/home/container/paper/$VERSION/paper-$VERSION.jar"

curl -fsSL \
    -H "User-Agent: $USER_AGENT" \
    "$DOWNLOAD_URL" \
    -o "$JAR_PATH"

echo "[PaperMC Updater] Download complete"

# --------------------------------------------------
# Java Version Detection
# --------------------------------------------------

JAVA_BIN="java"

if [[ "$VERSION" == 26* ]]; then
    if command -v java25 >/dev/null 2>&1; then
        JAVA_BIN="java25"
    elif [ -x "/usr/lib/jvm/java-25-openjdk/bin/java" ]; then
        JAVA_BIN="/usr/lib/jvm/java-25-openjdk/bin/java"
    fi
elif [[ "$VERSION" == 1.21* ]]; then
    if command -v java21 >/dev/null 2>&1; then
        JAVA_BIN="java21"
    fi
fi

echo "[PaperMC Updater] Using Java executable: $JAVA_BIN"

# --------------------------------------------------
# Start Server
# --------------------------------------------------

exec "$JAVA_BIN" \
-Xms128M \
-Xmx"${adjusted_memory}M" \
-XX:+UseG1GC \
-XX:+ParallelRefProcEnabled \
-XX:MaxGCPauseMillis=200 \
-XX:+UnlockExperimentalVMOptions \
-XX:+DisableExplicitGC \
-XX:+AlwaysPreTouch \
-XX:G1NewSizePercent=30 \
-XX:G1MaxNewSizePercent=40 \
-XX:G1HeapRegionSize=8M \
-XX:G1ReservePercent=20 \
-XX:G1HeapWastePercent=5 \
-XX:G1MixedGCCountTarget=4 \
-XX:InitiatingHeapOccupancyPercent=15 \
-XX:G1MixedGCLiveThresholdPercent=90 \
-XX:G1RSetUpdatingPauseTimePercent=5 \
-XX:SurvivorRatio=32 \
-XX:+PerfDisableSharedMem \
-XX:MaxTenuringThreshold=1 \
-Dusing.aikars.flags=https://mcflags.emc.gs \
-Daikars.new.flags=true \
-jar "$JAR_PATH" nogui
