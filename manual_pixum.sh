#!/bin/bash

# Check if a JSON file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path-to-json-file>"
    exit 1
fi

# Read JSON file
JSON_FILE=$1
INDEX=3

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to use this script."
    exit 1
fi

# Parse variables from the JSON file
FIRST_NAME=$(jq -r ".[$INDEX].first_name" "$JSON_FILE")
LAST_NAME=$(jq -r ".[$INDEX].last_name" "$JSON_FILE")
ADDRESS=$(jq -r ".[$INDEX].address" "$JSON_FILE")
ZIP_CODE=$(jq -r ".[$INDEX].zip_code" "$JSON_FILE")
TOWN=$(jq -r ".[$INDEX].town" "$JSON_FILE")
IMAGE_URL=$(jq -r ".[$INDEX].image_url" "$JSON_FILE")

echo $IMAGE_URL

# Function to pause and wait for user confirmation
pause() {
    echo "Press Enter to continue..."
    read -r
}

# Function to tap a location on the screen
tap() {
    local x=$1
    local y=$2
    echo "Tapping at location ($x, $y)"
    pause
    adb shell input tap "$x" "$y"
}

# Function to input text into a field
input_text() {
    local text=$1
    local escaped_text=$(echo "$text" | sed 's/ /%s/g' | sed 's/ä/ae/g' | sed 's/ö/oe/g' | sed 's/ü/ue/g' | sed 's/ß/ss/g' | sed 's/Ä/Ae/g' | sed 's/Ö/Oe/g' | sed 's/Ü/Ue/g')
    echo "Inputting text: $text"
    adb shell input text "$escaped_text"
}

# Function to scroll
scroll() {
    local direction=$1
    echo "Scrolling $direction"
    pause

    if [ "$direction" == "down" ]; then
        # Scroll Down (Swipe Up)
        adb shell input swipe 500 1500 500 500 300
    elif [ "$direction" == "up" ]; then
        # Scroll Up (Swipe Down)
        adb shell input swipe 500 500 500 1500 300
    else
        echo "Invalid direction. Use 'up' or 'down'."
    fi
}

# Define the target DCIM directory on the Android device
DCIM_DIR="/sdcard/DCIM/"

# Clear the DCIM folder on the device
echo "Clearing the DCIM folder on the device..."
adb shell rm -rf "${DCIM_DIR}*"

if [ $? -eq 0 ]; then
    echo "DCIM folder cleared successfully."
else
    echo "Failed to clear the DCIM folder."
    exit 1
fi

# Download the image
OUTPUT_FILE="downloaded_image.jpg"
echo "Downloading image from $IMAGE_URL..."
curl -o "$OUTPUT_FILE" "$IMAGE_URL"

# Check if the download was successful
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Failed to download the image."
    exit 1
fi

echo "Image downloaded as $OUTPUT_FILE."

# Push the image to the Android DCIM folder
echo "Saving image to Android DCIM folder..."
adb push "$OUTPUT_FILE" "$DCIM_DIR"

# Verify if the image was transferred successfully
if [ $? -eq 0 ]; then
    echo "Image successfully saved to $DCIM_DIR."
else
    echo "Failed to save the image to $DCIM_DIR."
fi

# Trigger media scanner to scan the new image for the Pixum App to see the changes
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM/downloaded_image.jpg

# Cleanup local image file
rm "$OUTPUT_FILE"

# Define app package and activity
PACKAGE_NAME="com.pixum.android.photoworld"
ACTIVITY_NAME=".MainActivity"

# Close all background apps and clear app data
adb shell am force-stop "$PACKAGE_NAME"
adb shell pm clear "$PACKAGE_NAME"

# Grant media permissions
adb shell pm grant "$PACKAGE_NAME" android.permission.READ_MEDIA_IMAGES
adb shell appops set "$PACKAGE_NAME" READ_MEDIA_IMAGES allow

# Launch the app
echo "Launching app: $PACKAGE_NAME"
adb shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"

# Example automation sequence
# 1. Tap on "Next" button
tap 550 2255

# 2. Tap on Second "Next" button
tap 550 2255

# 3. Tap on "Get Started" button
tap 550 2255

# 4. Tap on "X" button to remove welcome message
tap 985 620

# 5. Scroll down to Postcards
scroll down
scroll down
scroll down

# 6. Tap on "Postcards" button
tap 550 630

# Customize the backside of the Postcard
# 7. Tap on bottom right corner "Next" button
tap 860 2270

# 8. Tap on second bottom right corner "Next" button
tap 860 2270

# 9. Tap on bottom middle "Grant access" button
tap 550 2185

# Open DCIM Album
# 10. Tap on second bottom right corner "Next" button
tap 485 580

# 11. Tap on first photo in album
tap 175 800

# 12. Tap on top right corner "Done" button
tap 990 135

# Customize the backside of the Postcard
# 13. Tap on right postcard icon
tap 780 1810

# 14. Tap on edit Address icon
tap 700 1130

# Input Address Details
# 15. Tap on "First Name" field and input text
tap 500 570
input_text "$FIRST_NAME"

# 16. Tap on "Last Name" field and input text
tap 500 720
input_text "$LAST_NAME"

# 17. Tap on "Address" field and input text
tap 500 880
input_text "$ADDRESS"

# 18. Tap on "Zip Code" field and input text
tap 500 1180
input_text "$ZIP_CODE"

# 19. Tap on "Town" field and input text
tap 500 1325
input_text "$TOWN"

# 19.5 Close the keyboard
tap 115 2330

# 20. Tap on "Country" field and select top corner Germany
tap 500 1500
tap 225 405

# 21. Tap on "ADD NEW ADDRESS" button and input text
tap 760 2270

# 22. Tap on "SAVE CHANGES" button
tap 550 2260

# Checkout the Postcard
# 23. Tap on bottom right corner "CHECKOUT" button and await loading
tap 890 2260

# 24. Tap on bottom right corner "ADD TO CART" button and await animation
tap 890 2260

# 25. Tap on bottom middle "Apply Voucher" button and input text
tap 165 1010
input_text "XMASPOST"

# 26. Tap on right corner "APPLY" button and await animation
tap 700 1135

# 27. Tap on middle "OK" button for voucher animation
tap 535 1530

# Proceed to Payment
# 28. Tap on bottom right corner "PROCEED TO PAYMENT" button
tap 780 2270

echo "Automation complete."