# Function to prepend a green checkmark to a text message
success() {
    # Green checkmark Unicode character
    green_checkmark="\u2714"

    # Print the checkmark and the provided message
    echo -e "\033[32m$green_checkmark $1\033[0m"
}

headline() {
    # Print the checkmark and the provided message
    echo -e "\e[34m│ $1\e[0m"
}
