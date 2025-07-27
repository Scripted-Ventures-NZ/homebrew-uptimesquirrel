class UptimesquirrelAgent < Formula
  desc "System monitoring agent for UptimeSquirrel"
  homepage "https://uptimesquirrel.com"
  url "https://app.uptimesquirrel.com/downloads/agent/uptimesquirrel_agent_macos.py"
  version "1.2.9"
  sha256 "aca68caa31f383551721b8eba874321d16e5ff4f8ecdd1f378c4d013c134d1dc"

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

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/source/c/charset-normalizer/charset_normalizer-3.3.2.tar.gz"
    sha256 "f30c3cb33b24454a82faecaf01b19c18562b1e89558fb6c56de4d9118a032fd5"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/source/i/idna/idna-3.6.tar.gz"
    sha256 "9ecdbbd083b06798ae1e86adcbfe8ab1479cf864e4ee30fe4e46a003d12491ca"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/source/u/urllib3/urllib3-2.2.0.tar.gz"
    sha256 "051d961ad0c62a94e50ecf1af379c3aba230c66c710493493560c0c223c49f20"
  end

  def install
    # Create a virtual environment
    venv = virtualenv_create(libexec, "python3.11")
    
    # Install Python dependencies
    venv.pip_install resources
    
    # Install the agent script
    libexec.install "uptimesquirrel_agent_macos.py" => "uptimesquirrel_agent.py"
    
    # Create wrapper script
    (bin/"uptimesquirrel-agent").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/python" "#{libexec}/uptimesquirrel_agent.py" "$@"
    EOS
    
    # Create directories
    (etc/"uptimesquirrel").mkpath
    (var/"uptimesquirrel").mkpath
    (var/"log/uptimesquirrel").mkpath
    
    # Install sample configuration
    (etc/"uptimesquirrel").install "agent.conf.sample" => "agent.conf.sample" if File.exist?("agent.conf.sample")
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
  end

  service do
    run [opt_bin/"uptimesquirrel-agent", "-c", etc/"uptimesquirrel/agent.conf"]
    keep_alive true
    log_path var/"log/uptimesquirrel/agent.log"
    error_log_path var/"log/uptimesquirrel/agent.error.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      To configure the UptimeSquirrel agent:
        1. Edit the configuration file:
           #{etc}/uptimesquirrel/agent.conf

        2. Add your agent API key to the configuration

        3. Start the service:
           brew services start uptimesquirrel-agent

      To view logs:
        tail -f #{var}/log/uptimesquirrel/agent.log
        tail -f #{var}/log/uptimesquirrel/agent.error.log

      To check agent status:
        uptimesquirrel-agent --status
    EOS
  end

  test do
    system "#{bin}/uptimesquirrel-agent", "--version"
  end
end