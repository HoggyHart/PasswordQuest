import asyncio
from bleak import BleakScanner

async def scan_devices():
    devices = await BleakScanner.discover()
    for device in devices:
        print(f"Device: {device.address} - {device.name}")
        
asyncio.set_event_loop(asyncio.new_event_loop())
loop = asyncio.get_event_loop()
loop.run_until_complete(scan_devices())

# from this i got WillPhone's BTUUID as D5BABFE3-7ABA-8370-97C5-0D6078D57B5F

import asyncio
from bleak import BleakClient, BleakError

async def connect_to_device():
    device_address = "D5BABFE3-7ABA-8370-97C5-0D6078D57B5F"
    try:
        async with BleakClient(device_address) as client:
            await client.connect()
            print(f"Connected to {device_address}")
    except BleakError as e:
        print(f"Error connecting to device: {e}")

loop = asyncio.get_event_loop()
loop.run_until_complete(connect_to_device())