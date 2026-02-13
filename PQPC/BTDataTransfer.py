import asyncio
from bleak import BleakClient

CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"

async def send_and_receive_data():
    device_address = "D5BABFE3-7ABA-8370-97C5-0D6078D57B5F"
    async with BleakClient(device_address) as client:
        await client.connect()
        print(f"Connected to {device_address}")

        # Write data to a characteristic
        data_to_send = b"Hello, Bluetooth!"
        await client.write_gatt_char(CHARACTERISTIC_UUID, data_to_send)
        print(f"Sent data: {data_to_send}")

        # Read data from a characteristic
        received_data = await client.read_gatt_char(CHARACTERISTIC_UUID)
        print(f"Received data: {received_data}")

asyncio.set_event_loop(asyncio.new_event_loop())
loop = asyncio.get_event_loop()
loop.run_until_complete(send_and_receive_data())