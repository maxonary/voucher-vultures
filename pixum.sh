# !/bin/bash

# Check if a JSON file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path-to-json-file>"
    exit 1
fi

# Read JSON file
JSON_FILE=$1
INDEX=0

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

# Wait for the app to load
sleep 4

# Function to tap a location on the screen
tap() {
    local x=$1
    local y=$2
    echo "Tapping at location ($x, $y)"
    adb shell input tap "$x" "$y"
}

# Function to input text into a field
input_text() {
    local text=$1
    local escaped_text=$(echo "$text" | sed 's/ /%s/g' | sed 's/ä/ae/g' | sed 's/ö/oe/g' | sed 's/ü/ue/g' | sed 's/ß/ss/g' | sed 's/Ä/Ae/g' | sed 's/Ö/Oe/g' | sed 's/Ü/Ue/g')
    echo "Inputting text: $text"
    adb shell input text "$escaped_text"
}

scroll() {
    local direction=$1
    echo "Scrolling $direction"

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


# Example automation sequence
# 1. Tap on "Next" button
tap 550 2255
sleep 1

# 2. Tap on Second "Next" button
tap 550 2255
sleep 1

# 3. Tap on "Get Started" button
tap 550 2255
sleep 16

# 4. Tap on "X" button to remove welcome message
tap 985 620
sleep 1

# 5. Scroll down to Postcards
scroll down
scroll down
scroll down
sleep 1

# 6. Tap on "Postcards" button
tap 550 630
sleep 3


# Edit the Postcard

# 6. Tap on bottom right corner "Next" button
tap 860 2270
sleep 0.5

# 7. Tap on second bottom right corner "Next" button
tap 860 2270
sleep 0.5

# 8. Tap on bottom middle "Grant access" button
tap 550 2185
sleep 0.5

# 9. Tap on middle "Allow all" button to enable Photo Access
# tap 525 1350
# sleep 0.5

# Open DCIM Album
# 10. Tap on second bottom right corner "Next" button
tap 485 580
sleep 1

# 11. Tap on first photo in album
tap 175 800
sleep 1

# 12. Tap on top right corner "Done" button
tap 990 135
sleep 1

# Customize the backside of the Postcard
# 13. Tap on right postcard icon
sleep 2
tap 780 1810
sleep 1

# 14. Tap on edit Address icon
tap 700 1130
sleep 1

# Input Address Details
# 15. Tap on "First Name" field and input text
tap 500 570
input_text "$FIRST_NAME"
sleep 1

# 16. Tap on "Last Name" field and input text
tap 500 720
input_text "$LAST_NAME"
sleep 1

# 17. Tap on "Address" field and input text
tap 500 880
input_text "$ADDRESS"
sleep 1

# 18. Tap on "Zip Code" field and input text
tap 500 1180
input_text "$ZIP_CODE"
sleep 1

# 19. Tap on "Town" field and input text
tap 500 1325
input_text "$TOWN"
sleep 1

# 19.5 Close the keyboard
tap 115 2330
sleep 1

# 20. Tap on "Country" field and select top corner Germany
tap 500 1500
sleep 1
tap 225 405
sleep 1

# 21. Tap on "ADD NEW ADDRESS" button and input text
tap 760 2270
sleep 1

# 22. Tap on "SAVE CHANGES" button
tap 550 2260
sleep 1

# Checkout the Postcard
# 23. Tap on bottom right corner "CHECKOUT" button and await loading
tap 890 2260
sleep 3

# 23. Tap on bottom right corner "ADD TO CART" button and await animation
tap 890 2260
sleep 4

# 24. Tap on bottom middle "Apply Voucher" button and input text
tap 165 1010
sleep 1
input_text "XMASPOST"
sleep 1

# 25. Tap on right corner "APPLY" button and await animation
tap 700 1135
sleep 3

# 26. Tap on middle "OK" button for voucher animation
tap 535 1530
sleep 1

# Proceed to Payment
# 27. Tap on bottom right corner "PROCEED TO PAYMENT" button
tap 780 2270
sleep 2

# Enter Email Address for Account Creation
# 28. "Email Address" input text
input_text "user$(openssl rand -hex 8)@gmail.com"
sleep 1

# 29. Tap on middle "NEXT" button
tap 535 830
sleep 1

# 30. Open "PASSWORD" field and input text
tap 535 630
input_text "8ZrsDyUTuNQ!PP5ZD45VYDQALyp"

# 31. Tap on "TITLE" field, await and not select gender
# tap 535 830
# sleep 1
# tap 535 830

# 32. Tap on "FIRST NAME" field and input text
tap 535 990
input_text "$FIRST_NAME"
sleep 1

# 33. Tap on "LAST NAME" field and input text
tap 535 1160
input_text "$LAST_NAME"
sleep 1

# 33.5 Close the keyboard
tap 115 2330
sleep 1

# 34. Tap on the "Terms and Conditions" and "Privacy Statement" checkboxes
tap 100 1325
tap 100 1430
sleep 1

# 35. Tap on "REGISTER" button
tap 535 1715
sleep 5

# Billing Page
# 36. Remove Google password manager prompt
# tap 180 2230
# sleep 2

# 37. Tap on "ADDRESS" field and input text
tap 535 1125
input_text "$ADDRESS"
sleep 0.5

# 37.5 Close the keyboard
tap 115 2330
sleep 1

# 38. Tap on "ZIP CODE" field and input text
tap 535 1475
input_text "$ZIP_CODE"
sleep 0.5

# 38.5 Close the keyboard
tap 115 2330
sleep 1

# 39. Tap on "TOWN" field and input text
tap 535 1580
input_text "$TOWN"
sleep 0.5

# 38.5 Close the keyboard
tap 115 2330
sleep 1

# 40. Scroll down to finish order
scroll down
sleep 1

# 41. Tap checkbox for "I have read and accept the General Terms and Conditions" and "I have read and accept the Privacy Statement"
tap 75 1950
tap 75 2070

# 42. Tap on "PROCEED" button
tap 535 2220
sleep 3

echo "Automation complete with the following details:"
echo "First Name: $FIRST_NAME"
echo "Last Name: $LAST_NAME"
echo "Address: $ADDRESS"
echo "Zip Code: $ZIP_CODE"
echo "Town: $TOWN"
echo "Image URL: $IMAGE_URL"