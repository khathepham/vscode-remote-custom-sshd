
# VS Code Server Manual Deployment Scripts

These scripts download and deploy the VS Code Server version that matches your local VS Code installation to a remote Linux host using SSH/SCP.

Supported platforms:

- Linux/macOS (`deploy-vscode-server.sh`)
- Windows Command Prompt (`deploy-vscode-server.cmd`)

This is useful when the VS Code Remote-SSH extension cannot automatically download the server, such as in:

- Restricted network environments
- Air-gapped systems
- Corporate proxy environments
- Hosts without internet access
- Environments where outbound access to Microsoft download endpoints is blocked

---

## How It Works

The script:

1. Detects the commit ID of your local VS Code installation.
2. Downloads the matching VS Code Server package.
3. Creates the target directory on the remote host.
4. Copies the server archive via SCP.
5. Extracts the server files on the remote host.
6. Removes the archive after extraction.
7. Creates the deployment flag file expected by Remote-SSH.

Once completed, VS Code Remote-SSH should recognize the server installation and connect normally.

---

## Requirements

### Local Machine

VS Code Installed

### Remote Machine

The target machine must:

- Run Linux
- Accept SSH connections
- Have `tar` installed
- Have write access to the user's home directory

The deployment location is:

```text
~/.vscode-server/bin/<commit-id> 
```

---

## Usage

### Full usage on Windows
Using a Powershell Terminal on your Local Machine, edit, copy and run the following command. Remove angle brackets where requested. 

```bash
git clone https://cfgitlabprd01v.psb.bls.gov/Pham_K/vscode-manual-deploy
./vscode-manual-deploy/deploy-vscode-server.cmd -u <username> -h <servername>
```

Example:
```bash 
git clone https://cfgitlabprd01v.psb.bls.gov/Pham_K/vscode-manual-deploy
./vscode-manual-deploy/deploy-vscode-server.cmd -u pham_k -h tcedvlp
```

---

### Linux/macOS

```bash
chmod +x deploy-vscode-server.sh 
./deploy-vscode-server.sh -u ubuntu -h myserver.example.com 
```

Custom port:

```bash
./deploy-vscode-server.sh -u ubuntu -h myserver.example.com -p 2222 
```

### Windows CMD

```cmd
deploy-vscode-server.cmd -u ubuntu -h myserver.example.com 
```

Custom port:

```cmd
deploy-vscode-server.cmd -u ubuntu -h myserver.example.com -p 2222 
```

---

## Parameters

| Parameter | Required | Description                   |
| --------- | -------- | ----------------------------- |
| `-u`    | Yes      | Remote SSH username           |
| `-h`    | Yes      | Remote hostname or IP address |
| `-p`    | No       | SSH port (defaults to `22`) |

---

## Troubleshooting

### Could Not Determine VS Code Commit ID

Run:

```bash
code --version 
```

or

```cmd
code --version 
```

### SSH Connection Fails

Verify manual connectivity first.

### Permission Denied

Ensure the remote user can authenticate via SSH and write to their home directory.

---

## License

Provided as-is without warranty. Use at your own risk.
