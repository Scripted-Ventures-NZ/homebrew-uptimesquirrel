# Homebrew Tap for UptimeSquirrel

This is the official Homebrew tap for [UptimeSquirrel](https://uptimesquirrel.com), providing easy installation of the UptimeSquirrel monitoring agent on macOS.

## Quick Start

```bash
brew tap scripted-ventures-nz/uptimesquirrel
brew install uptimesquirrel-agent
```

## What is UptimeSquirrel?

UptimeSquirrel is a comprehensive monitoring platform that helps you track the health and performance of your servers, websites, and services. The agent collects system metrics including CPU, memory, disk, and network usage.

## Installation

### 1. Add the Tap

```bash
brew tap scripted-ventures-nz/uptimesquirrel
```

### 2. Install the Agent

```bash
brew install uptimesquirrel-agent
```

### 3. Configure

Get your agent key from [app.uptimesquirrel.com/agents](https://app.uptimesquirrel.com/agents), then:

```bash
# Edit the configuration file
nano /usr/local/etc/uptimesquirrel/agent.conf

# Add your agent key to the [api] section
```

### 4. Start the Service

```bash
# Start and enable auto-start
brew services start uptimesquirrel-agent

# Check status
brew services list | grep uptimesquirrel
```

## Configuration

The main configuration file is located at:
```
/usr/local/etc/uptimesquirrel/agent.conf
```

### Network Interfaces

To limit which network interfaces are monitored:
```
/usr/local/etc/uptimesquirrel/networks.json
```

### Disk Monitoring

To configure which disks are monitored:
```
/usr/local/etc/uptimesquirrel/disks.json
```

## Commands

```bash
# Check agent version
uptimesquirrel-agent --version

# Test configuration
uptimesquirrel-agent --test

# View current status
uptimesquirrel-agent --status

# View logs
tail -f /usr/local/var/log/uptimesquirrel/agent.log
tail -f /usr/local/var/log/uptimesquirrel/agent.error.log
```

## Updating

```bash
brew update
brew upgrade uptimesquirrel-agent
```

## Uninstalling

```bash
# Stop the service
brew services stop uptimesquirrel-agent

# Uninstall the agent
brew uninstall uptimesquirrel-agent

# Remove the tap (optional)
brew untap uptimesquirrel/uptimesquirrel

# Remove configuration (optional)
rm -rf /usr/local/etc/uptimesquirrel
```

## Troubleshooting

### Agent not starting?

1. Check your API key is correctly set in `/usr/local/etc/uptimesquirrel/agent.conf`
2. Check logs: `tail -f /usr/local/var/log/uptimesquirrel/agent.error.log`
3. Run manually to see errors: `uptimesquirrel-agent -c /usr/local/etc/uptimesquirrel/agent.conf`

### Permission issues?

The agent needs appropriate permissions to collect system metrics. If you encounter issues:

```bash
sudo brew services restart uptimesquirrel-agent
```

### Not seeing metrics?

1. Ensure your agent is registered at [app.uptimesquirrel.com/agents](https://app.uptimesquirrel.com/agents)
2. Check network connectivity to `agent-api.uptimesquirrel.com`
3. Verify the agent is running: `ps aux | grep uptimesquirrel`

## Requirements

- macOS 10.15 (Catalina) or later
- Homebrew
- Python 3.9 or later (installed automatically)

## Support

- 📚 Documentation: [docs.uptimesquirrel.com](https://docs.uptimesquirrel.com/agents/macos)
- 🐛 Issues: [GitHub Issues](https://github.com/Scripted-Ventures-NZ/homebrew-uptimesquirrel/issues)
- 📧 Email: support@uptimesquirrel.com
- 💬 Discord: [Join our community](https://discord.gg/uptimesquirrel)

## License

The UptimeSquirrel Agent is distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

Made with ❤️ by the UptimeSquirrel team