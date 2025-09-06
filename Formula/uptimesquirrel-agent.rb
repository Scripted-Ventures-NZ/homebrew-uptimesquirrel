class UptimesquirrelAgent < Formula
  include Language::Python::Virtualenv

  desc "System monitoring agent for UptimeSquirrel with check execution support"
  homepage "https://uptimesquirrel.com"
  url "https://app.uptimesquirrel.com/downloads/agent/uptimesquirrel_agent_macos.py?v=2.0.1"
  version "2.0.1"
  sha256 "cbddf7048d4853c644d2886851242160816817ba5b8577290326a015cefd87a4"

  depends_on "python@3.11"

  resource "psutil" do
    url "https://files.pythonhosted.org/packages/source/p/psutil/psutil-5.9.8.tar.gz"
    sha256 "6be126e3225486dff286a8fb9a06246a5253f4c7c53b475ea5f5ac934e64194c"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/source/r/requests/requests-2.31.0.tar.gz"
    sha256 "942c5a758f98d790eaed1a29cb6eefc7ffb0d1cf7af05c3d2791656dbd6ad1e1"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/source/c/certifi/certifi-2024.2.2.tar.gz"
    sha256 "0569859f95fc761b18b45ef421b1290a0f65f147e92a1e5eb3e635f9a5e4e66f"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/source/u/urllib3/urllib3-2.2.0.tar.gz"
    sha256 "051d961ad0c62a94e50ecf1af379c3aba230c66c710493493560c0c223c49f20"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/source/c/charset-normalizer/charset-normalizer-3.3.2.tar.gz"
    sha256 "f30c3cb33b24454a82faecaf01b19c18562b1e89558fb6c56de4d9118a032fd5"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/source/i/idna/idna-3.6.tar.gz"
    sha256 "9ecdbbd083b06798ae1e86adcbfe8ab1479cf864e4ee30fe4e46a003d12491ca"
  end

  # aiohttp dependencies for check execution
  resource "aiohttp" do
    url "https://files.pythonhosted.org/packages/source/a/aiohttp/aiohttp-3.12.15.tar.gz"
    sha256 "dfb4dd4d96e4e7dfdd3e7fcb7bf4ac20f3c79ea24d8bc93a7b07ed5fb7e999f7"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/source/m/multidict/multidict-6.6.4.tar.gz"
    sha256 "0487b2df05c46b7ff73b7fcb7abab6f51ea9b83ddc2b38262e29d2da6a3b63e"
  end

  resource "yarl" do
    url "https://files.pythonhosted.org/packages/source/y/yarl/yarl-1.20.1.tar.gz"
    sha256 "1de7e21b89e2a5d5dadc16a5b20cfa7a0eb0cc3b4cc89d7a2d2fb69adde94797"
  end

  resource "aiosignal" do
    url "https://files.pythonhosted.org/packages/source/a/aiosignal/aiosignal-1.4.0.tar.gz"
    sha256 "b40ca5f6cbb30e5c2071d96d2b9abacaeefe4b8e3a30c491a3d07f607a4edc5a"
  end

  resource "frozenlist" do
    url "https://files.pythonhosted.org/packages/source/f/frozenlist/frozenlist-1.7.0.tar.gz"
    sha256 "9c4b09f8b8b3af6d8b08b7c6f73a7a62a7fb67b5e2b23e21b3a45c06e6e0e78a"
  end

  resource "attrs" do
    url "https://files.pythonhosted.org/packages/source/a/attrs/attrs-25.3.0.tar.gz"
    sha256 "a567b48f12b29d5ba3ce17b36f2ad3b2dc8d8d5b9a80b29b7e95e5d7b35f8f4a"
  end

  def install
    # Create a virtualenv in libexec
    venv = virtualenv_create(libexec, "python3.11")
    
    # Install Python dependencies into the virtualenv
    venv.pip_install resources
    
    # Download and install check execution modules
    system "curl", "-s", "-o", "task_manager.py", "https://app.uptimesquirrel.com/downloads/agent/task_manager_macos.py"
    system "curl", "-s", "-o", "check_executor.py", "https://app.uptimesquirrel.com/downloads/agent/check_executor_macos.py"
    
    # Copy all agent files
    libexec.install "uptimesquirrel_agent_macos.py"
    libexec.install "task_manager.py"
    libexec.install "check_executor.py"
    
    # Create wrapper script
    (bin/"uptimesquirrel-agent").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/python" "#{libexec}/uptimesquirrel_agent_macos.py" "$@"
    EOS
    
    # Make wrapper executable
    chmod 0755, bin/"uptimesquirrel-agent"
    
    # Create directories
    (etc/"uptimesquirrel").mkpath
    (var/"uptimesquirrel").mkpath
    (var/"log/uptimesquirrel").mkpath
  end

  def post_install
    # Create default configuration if it doesn't exist
    config_file = etc/"uptimesquirrel/agent.conf"
    unless config_file.exist?
      config_file.write <<~EOS
        [api]
        url = https://agent-api.uptimesquirrel.com
        key = YOUR_AGENT_KEY_HERE

        [agent]
        # Check execution settings (v2.0+ - Business/Enterprise plans)
        check_execution_enabled = true
        max_concurrent_checks = 10
        agent_id = YOUR_AGENT_ID_HERE
        home_region = us-west-2

        [monitoring]
        interval = 60
        cpu_threshold = 80.0
        memory_threshold = 85.0
        disk_threshold = 90.0

        [services]
        # Add services to monitor (examples)
        # monitor_nginx = true
        # monitor_mysql = true
        # monitor_postgresql = true
        # monitor_redis = true
      EOS
    else
      # Update existing config if it's missing required sections
      config_content = config_file.read
      unless config_content.include?("check_execution_enabled")
        # Add check execution settings to existing config
        config_content = config_content.gsub(/\[agent\]/, "[agent]\n# Check execution settings (v2.0+ - Business/Enterprise plans)\ncheck_execution_enabled = true\nmax_concurrent_checks = 10")
        config_file.atomic_write(config_content)
      end
    end
    
    # Create networks.json if it doesn't exist
    networks_file = etc/"uptimesquirrel/networks.json"
    unless networks_file.exist?
      networks_file.write <<~JSON
        {
          "version": 1,
          "max_enabled_interfaces": 4,
          "interface_settings": {
            "en0": {
              "description": "Ethernet",
              "enabled": true,
              "display_order": 1
            },
            "en1": {
              "description": "Wi-Fi",
              "enabled": true,
              "display_order": 2
            }
          }
        }
      JSON
    end
  end

  service do
    run [opt_bin/"uptimesquirrel-agent", "-c", etc/"uptimesquirrel/agent.conf"]
    keep_alive true
    log_path var/"log/uptimesquirrel/agent.log"
    error_log_path var/"log/uptimesquirrel/agent.error.log"
    environment_variables PATH: std_service_path_env, HOMEBREW_NO_ENV_HINTS: "1"
  end

  def post_upgrade
    # Restart the service if it's running to load the new version
    if File.exist?("#{ENV["HOME"]}/Library/LaunchAgents/homebrew.mxcl.uptimesquirrel-agent.plist")
      system "brew", "services", "restart", "uptimesquirrel-agent"
      opoo "UptimeSquirrel agent service has been restarted to load the new version."
    end
  end

  def caveats
    <<~EOS
      To configure the UptimeSquirrel agent:
        1. Edit the configuration file:
           #{etc}/uptimesquirrel/agent.conf

        2. Add your agent API key from:
           https://app.uptimesquirrel.com/agents

        3. Start the service:
           brew services start uptimesquirrel-agent

      To view logs:
        tail -f #{var}/log/uptimesquirrel/agent.log
        tail -f #{var}/log/uptimesquirrel/agent.error.log

      To check agent status:
        uptimesquirrel-agent --status

      Network interfaces can be configured in:
        #{etc}/uptimesquirrel/networks.json
        
      Note: The agent service will be automatically restarted after upgrades.
    EOS
  end

  test do
    system "#{bin}/uptimesquirrel-agent", "--version"
  end
end