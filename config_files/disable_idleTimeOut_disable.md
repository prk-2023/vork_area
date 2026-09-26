# Disable Idle state:

Remote machine goes to sleep or dim thinking the user is idle for too long.
Append the below to .bashrs to prevent that. 

Linux systems actually allow unprivileged users to inhibit the idle state without needing a password prompt.

```bash 
# Prevent idle-based sleep/dimming during active SSH session (No password needed)
if [ -n "\(SSH_CLIENT" ] || [ -n "\)SSH_TTY" ]; then
    systemd-inhibit --what=idle --who="SSH User" --why="Prevent idle timeout during SSH" sleep infinity &
    INHIBIT_PID=$!
    trap 'kill $INHIBIT_PID 2>/dev/null' EXIT
fi

```
