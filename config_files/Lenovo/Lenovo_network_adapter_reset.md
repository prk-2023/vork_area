To add the provided systemd service and activate it to run at boot, follow these steps:

1. **Create the systemd service file**:
   - Open a terminal and use a text editor (e.g., `nano` or `vim`) to create a new service file. We'll name it `reset-e1000e.service` in this example.

   ```bash
   sudo nano /etc/systemd/system/reset-e1000e.service
   ```

2. **Add the service content**:
   - Paste the content you provided into the file.

   ```ini
   [Unit]
   Description=Reset e1000e during boot
   After=network.target

   [Service]
   Type=oneshot
   ExecStart=/bin/bash -c 'modprobe -r e1000e; echo 1 > /sys/bus/pci/devices/0000:00:19.0/reset; modprobe e1000e'
   RemainAfterExit=true

   [Install]
   WantedBy=multi-user.target
   ```

   This service removes and reloads the `e1000e` module during boot to reset the network device.

3. **Save and close the file**:
   - In `nano`, press `CTRL + X`, then press `Y` to confirm saving, and `Enter` to save the file.

4. **Reload systemd to recognize the new service**:
   ```bash
   sudo systemctl daemon-reload
   ```

5. **Enable the service to start on boot**:
   ```bash
   sudo systemctl enable reset-e1000e.service
   ```

   This command ensures the service runs at boot time.

6. **Start the service immediately (optional)**:
   If you want to test the service right away without rebooting, you can start it with:

   ```bash
   sudo systemctl start reset-e1000e.service
   ```

7. **Verify the service status**:
   To check if the service is running correctly, use:

   ```bash
   sudo systemctl status reset-e1000e.service
   ```

8. **Reboot to test**:
   Finally, reboot the system to ensure the service runs on startup:

   ```bash
   sudo reboot
   ```

Once the system restarts, the `reset-e1000e` service should automatically run and reset the `e1000e` network device during the boot process.
