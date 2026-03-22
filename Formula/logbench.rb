class Logbench < Formula
  desc "Local log viewer and ingestion service"
  homepage "https://github.com/albingroen/logbench"
  version "0.1.9"
  url "https://github.com/albingroen/logbench/releases/download/v0.1.9/logbench-0.1.9-darwin-arm64.tar.gz"
  sha256 "5c45af85547e21164a1a2af1b7631480ea7890a3b577e4e0f2a0c9c6079c3197"
  license "MIT"

  depends_on "bun"
  depends_on arch: :arm64

  def install
    libexec.install ".output", "prisma", ".logbench-version"

    bin.install "bin/logbench"
    inreplace bin/"logbench",
              '$(cd "$(dirname "$0")/../libexec" && pwd)',
              libexec.to_s
    inreplace bin/"logbench",
              "exec bun run",
              "exec #{Formula["bun"].opt_bin}/bun run"
  end

  def post_install
    # Restart the service after upgrade so the new hashed assets are served
    if quiet_system "/bin/launchctl", "list", "homebrew.mxcl.logbench"
      system "brew", "services", "restart", "logbench"
    end
  end

  def caveats
    <<~EOS
      Logbench runs on http://localhost:1447 by default.

      Data is stored in #{var}/logbench/.

      Start as a background service:
        brew services start logbench

      After upgrading, restart the service:
        brew services restart logbench
    EOS
  end

  service do
    run [opt_bin/"logbench"]
    keep_alive true
    log_path var/"log/logbench.log"
    error_log_path var/"log/logbench.log"
    environment_variables PORT: "1447",
                          DATABASE_URL: "file:#{var}/logbench/logbench.db",
                          LOGBENCH_DATA: "#{var}/logbench"
  end

  test do
    port = free_port
    pid = fork do
      ENV["PORT"] = port.to_s
      ENV["DATABASE_URL"] = "file:#{testpath}/test.db"
      ENV["LOGBENCH_DATA"] = testpath.to_s
      exec bin/"logbench"
    end
    sleep 3
    assert_match "<!DOCTYPE html>", shell_output("curl -s http://127.0.0.1:#{port}/")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
