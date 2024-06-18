# Firewise Tech
## IoT Challenges 2024

# Getting Started 
1. **Raspberry Pi (Coordinator)**
    - Download the Z3gateway for Raspberry Pi. [Reference Link](https://sunmaysky.blogspot.com/2022/07/how-to-build-emberznet-7100-z3gateway.html)
    - Connect the USB port with efr32mg24 (bootloader, uart-ncp-xmodem).
    - Switch to the ```Pi``` branch and then download them on the Raspberry Pi.
    - Run the Python file.
    
2. **EFR32MG24 (Node)**
    - Flash the bootloader first.
    - Switch to the ```efr32mg24``` branch to download it and then import it to Simplic Studio.

How to create a systemd service to accomplish this:

1. Create a service file for systemd.

Open a terminal and run the following command to create a new service file:

```bash
sudo nano /etc/systemd/system/auto_z3gw.service
```

2. Put the following content into the file:

```plaintext
[Unit]
Description=Auto Start Z3gateway Service
After=network.target

[Service]
Type=simple
ExecStart=/home/pi/documents/Python/myenv/bin/python /home/pi/documents/Python/Fw_prj/ru>
WorkingDirectory=/home/pi/documents/Python/Fw_prj
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

3. Save and close the file (in Nano, press `Ctrl + O`, then press `Enter`, and then press `Ctrl + X` to exit).

4. Reload systemd to recognize the changes:

```bash
sudo systemctl daemon-reload
```

5. Enable the service to run after every boot:

```bash
sudo systemctl enable auto_z3gw.service
```

6. Start the service immediately:

```bash
sudo systemctl start auto_z3gw.service
```

After this step, the `auto_z3gw.sh` script will automatically run every time the system boots. You can also reboot the system to check if the service has been successfully activated:

```bash
sudo reboot
```

After the system reboots, check the status of the service by running the command:

```bash
sudo systemctl status auto_z3gw.service
```

If everything goes as expected, you will see that the service is active and has been activated to automatically run after every boot.