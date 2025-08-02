class UptimesquirrelAgent < Formula
  include Language::Python::Virtualenv

  desc "System monitoring agent for UptimeSquirrel"
  homepage "https://uptimesquirrel.com"
  url "https://app.uptimesquirrel.com/downloads/agent/uptimesquirrel_agent_macos.py?v=1.2.15"
  version "1.2.15"
  sha256 "7e82b43dda8fa5134cf8a4e9ea8d5e3319a3d542bb644658f7d6a7c9215d75e6"

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

  def install
    # Create a virtualenv in libexec
    venv = virtualenv_create(libexec, "python3.11")
    
    # Install Python dependencies into the virtualenv
    venv.pip_install resources
    
    # Copy the agent script
    libexec.install "uptimesquirrel_agent_macos.py"
    
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
        interval = 60
        hostname = #{`hostname -s`.strip}
        
        # macOS specific settings
        [macos]
        monitor_launchd = true
        monitor_temperature = true
      EOS
    end
    
    # Create networks.json if it doesn't exist
    networks_file = etc/"uptimesquirrel/networks.json"
    unless networks_file.exist?
      networks_file.write <<~JSON
        {
          "interfaces": {
            "en0": {"enabled": true, "description": "Wi-Fi"},
            "en1": {"enabled": true, "description": "Ethernet"}
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
    EOS
  end

  test do
    system "#{bin}/uptimesquirrel-agent", "--version"
  end
end