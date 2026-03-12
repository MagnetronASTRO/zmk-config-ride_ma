#!/bin/bash
set -e

DOCKER_IMAGE="zmkfirmware/zmk-build-arm:stable"
WORKDIR="/workspaces/zmk-config"

# Initialize (only needed first time)
if [ ! -d "zmk" ]; then
    echo "==> Initializing West workspace..."
    docker run --rm -v "$(pwd)":$WORKDIR -w $WORKDIR $DOCKER_IMAGE \
        bash -c 'west init -l config && west update && west zephyr-export'
fi

# Build both halves in parallel using separate containers (avoids shared cmake state conflicts)
echo "==> Building ride_left and ride_right in parallel..."

docker run --rm -v "$(pwd)":$WORKDIR -w $WORKDIR $DOCKER_IMAGE \
    bash -c "west zephyr-export && west build -s zmk/app -b nice_nano//zmk -d build/left -p -- \
      -DSHIELD=ride_left -DZMK_CONFIG=$WORKDIR/config" &
LEFT_PID=$!

docker run --rm -v "$(pwd)":$WORKDIR -w $WORKDIR $DOCKER_IMAGE \
    bash -c "west zephyr-export && west build -s zmk/app -b nice_nano//zmk -d build/right -p -- \
      -DSHIELD=ride_right -DZMK_CONFIG=$WORKDIR/config" &
RIGHT_PID=$!

wait $LEFT_PID && wait $RIGHT_PID

echo ""
echo "==> Copying firmware files to firmware/ folder..."
mkdir -p firmware
cp build/left/zephyr/zmk.uf2 firmware/left_ride.uf2
cp build/right/zephyr/zmk.uf2 firmware/right_ride.uf2

echo ""
echo "✅ Done! Firmware files:"
echo "   Left:  firmware/left_ride.uf2"
echo "   Right: firmware/right_ride.uf2"
