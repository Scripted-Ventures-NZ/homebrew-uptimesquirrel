class UptimesquirrelAgent < Formula
  include Language::Python::Virtualenv

  desc "System monitoring agent for UptimeSquirrel with check execution support"
  homepage "https://uptimesquirrel.com"
  url "https://app.uptimesquirrel.com/downloads/agent/uptimesquirrel_agent_macos.py?v=2.0.3"
  version "2.0.3"
  sha256 "ebc6f867d46388c46b796a0301aab427af6b693142cdb7e532e2f60fbef2c42e"

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
    sha256 "4fc61385e9c98d72fcdf47e6dd81833f47b2f77c114c29cd64a361be57a763a2"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/source/m/multidict/multidict-6.6.4.tar.gz"
    sha256 "d2d4e4787672911b48350df02ed3fa3fffdc2f2e8ca06dd6afdf34189b76a9dd"
  end

  resource "yarl" do
    url "https://files.pythonhosted.org/packages/source/y/yarl/yarl-1.20.1.tar.gz"
    sha256 "d017a4997ee50c91fd5466cef416231bb82177b93b029906cefc542ce14c35ac"
  end

  resource "aiosignal" do
    url "https://files.pythonhosted.org/packages/source/a/aiosignal/aiosignal-1.4.0.tar.gz"
    sha256 "f47eecd9468083c2029cc99945502cb7708b082c232f9aca65da147157b251c7"
  end

  resource "frozenlist" do
    url "https://files.pythonhosted.org/packages/source/f/frozenlist/frozenlist-1.7.0.tar.gz"
    sha256 "2e310d81923c2437ea8670467121cc3e9b0f76d3043cc1d2331d56c7fb7a3a8f"
  end

  resource "attrs" do
    url "https://files.pythonhosted.org/packages/source/a/attrs/attrs-25.3.0.tar.gz"
    sha256 "75d7cefc7fb576747b2c81b4442d4d4a1ce0900973527c011d1030fd3bf4af1b"
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
    # Always restart the service after upgrade to ensure new version is loaded
    ohai "Restarting UptimeSquirrel agent service to load v#{version}..."
    
    # Use quiet flag to suppress errors if service isn't running
    system "brew", "services", "restart", "uptimesquirrel-agent", "--quiet"
    
    opoo "IMPORTANT: UptimeSquirrel agent has been upgraded to v#{version}"
    opoo "The service has been restarted automatically to load the new version."
    opoo "Run 'uptimesquirrel-agent --status' to verify the new version is active."
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