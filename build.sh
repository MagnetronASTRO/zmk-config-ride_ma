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

# Build both halves in a single container session
echo "==> Building ride_left and ride_right..."
docker run --rm -v "$(pwd)":$WORKDIR -w $WORKDIR $DOCKER_IMAGE \
    bash -c "
    west zephyr-export &&
    echo '==> Building ride_left...' &&
    west build -s zmk/app -b nice_nano -d build/left -p -- \
      -DSHIELD=ride_left -DZMK_CONFIG=$WORKDIR/config &&
    echo '==> Building ride_right...' &&
    west build -s zmk/app -b nice_nano -d build/right -p -- \
      -DSHIELD=ride_right -DZMK_CONFIG=$WORKDIR/config
  "

echo ""
echo "✅ Done! Firmware files:"
echo "   Left:  build/left/zephyr/zmk.uf2"
echo "   Right: build/right/zephyr/zmk.uf2"
