#!/bin/bash
VERSION="1.0.0"
# Build Love Live2D
echo "Building Love Live2D..."
# dotnet build -c Release
# echo "Build process completed for all target OS architectures."
# Define the target operating systems and architectures
TARGET_OS_ARCHITECTURES=("win-x64" "win-arm64" "osx-x64" "osx-arm64")
TARGET_FRAMEWORKS=("net6.0" "net7.0")

# Build the project for each target OS architecture
for os_arch in "${TARGET_OS_ARCHITECTURES[@]}"
do
    for framework in "${TARGET_FRAMEWORKS[@]}"
    do
        echo "Building for $os_arch architecture..."
        dotnet publish -c Release -f "$framework" -r "$os_arch" --no-self-contained

        # Check if build was successful
        if [ $? -eq 0 ]; then
            echo "Build for $os_arch completed successfully."
        else
            echo "Build for $os_arch failed."
            exit 1  # Exit the script with an error code
        fi
    done
done

echo "Build process completed for all target OS architectures."

SOURCE_DIR="src/rlm1501/sources/com/reprisesoftware/rlm"
STAGING_DIR="bin/Release/rlm1603/staging"
OUTPUT_DIR="bin/Release/rlm1603"
OUTPUT_JAR="bin/Release/rlm1603/rlm1603.jar"

# Create a clean staging directory to compile Java classes into
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

# Compile Java classes
# NOTE: Must target Java 8 (or lower) since Live2D Cubism 5.3 bundles JRE 17;
# compiling with a newer javac default would produce UnsupportedClassVersionError.
echo "Building rlm1603..."
javac --release 8 -d "${STAGING_DIR}" "${SOURCE_DIR}"/*.java -Xlint:unchecked
echo "Successfully build rlm1603."

# Check if compilation was successful
if [ $? -eq 0 ]; then
    # Create JAR file from staged classes only (avoid packing the jar into itself)
    echo "Packing rlm1603 as .jar..."
    rm -f "${OUTPUT_JAR}"
    jar cf "${OUTPUT_JAR}" -C "${STAGING_DIR}" .
    echo "JAR file '${OUTPUT_JAR}' created successfully."
else
    echo "Packing failed. JAR file not created."
fi

# Create "lib" directory to store modified "rlm1603.jar"
echo "Distributing rlm1603.jar for every architecture..."
for framework in "${TARGET_FRAMEWORKS[@]}"
do
    for os_arch in "${TARGET_OS_ARCHITECTURES[@]}"
    do
        # Copy rlm1603.jar to every architecture
        LIB_PATH="bin/Release/${framework}/${os_arch}/publish/lib"
        mkdir -p "${LIB_PATH}"
        cp "${OUTPUT_JAR}" "${LIB_PATH}"
        # Also copy to build output dir so the exe works when run directly from there
        OUTPUT_LIB_PATH="bin/Release/${framework}/${os_arch}/lib"
        mkdir -p "${OUTPUT_LIB_PATH}"
        cp "${OUTPUT_JAR}" "${OUTPUT_LIB_PATH}"
    done

    for os_arch in "${TARGET_OS_ARCHITECTURES[@]}"
    do
        # Make a zip file for every architecture to be distributed
        ZIP_OUTPUT="LoveLive2D-v${VERSION}-${framework}-${os_arch}.zip"
        cd "bin/Release/${framework}/${os_arch}/publish/"
        zip -r "../../../${ZIP_OUTPUT}" *
        cd "../../../../../" # build.sh directory
    done
done
