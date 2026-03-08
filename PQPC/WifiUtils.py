import pywifi
from pywifi import const
import time
def connect_to_wifi(ssid, password):
    """
    Attempts to connect to a specified Wi-Fi network.

    Args:
        ssid (str): The name of the Wi-Fi network.
        password (str): The password for the network.
    """
    wifi = pywifi.PyWiFi()
    iface = wifi.interfaces()[0]

    # Disconnect from any current connection
    iface.disconnect()
    time.sleep(2)  # Brief pause

    # Create a new profile object
    profile = pywifi.Profile()
    profile.ssid = ssid  # Network name
    profile.auth = const.AUTH_ALG_SHARED  # Common auth algorithm
    profile.akm.append(const.AKM_TYPE_WPA2PSK)  # Encryption type (WPA2)
    profile.cipher = const.CIPHER_TYPE_CCMP  # Cipher type
    profile.key = password  # The network password

    # Remove any existing profile for this network and add the new one
    iface.remove_all_network_profiles() #removes ALL, not just for this network. fix this pls
    tmp_profile = iface.add_network_profile(profile)

    # Attempt to connect
    #print(f"Attempting to connect to '{ssid}'...")
    iface.connect(tmp_profile)
    time.sleep(5)  # Wait for connection to establish

    # Check connection status
    if iface.status() == const.IFACE_CONNECTED:
        #print(f"Successfully connected to '{ssid}'!")
        return True
    else:
        #print(f"Failed to connect to '{ssid}'. Please check the password and network availability.")
        return False


def simple_wifi_manager():
    wifi = pywifi.PyWiFi()
    iface = wifi.interfaces()[0]

    # Scan
    print("Scanning...")
    iface.scan()
    time.sleep(5)
    networks = iface.scan_results()

    # Display list with numbers
    print("\nAvailable Networks:")
    for i, net in enumerate([n for n in networks if n.ssid]):
        print(f"{i+1}. {net.ssid} (Signal: {net.signal} dBm)")

    # Let user select
    try:
        choice = int(input("\nEnter the number of the network to connect to: ")) - 1
        selected_ssid = [n for n in networks if n.ssid][choice].ssid
        password = input(f"Enter password for '{selected_ssid}': ")

        connect_to_wifi(selected_ssid, password)

    except (IndexError, ValueError):
        print("Invalid selection.")