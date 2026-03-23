class Logbench < Formula
  desc "Local log viewer and ingestion service"
  homepage "https://github.com/albingroen/logbench"
  version "0.2.2"
  url "https://github.com/albingroen/logbench/releases/download/v0.2.2/logbench-0.2.2-darwin-arm64.tar.gz"
  sha256 "7c0d537114d69159e2ae0134e97ce164b19ff205fe2dee19e59593f9ba324eab"
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

  def caveats
    <<~EOS
      Logbench runs on http://localhost:1447 by default.

      Data is stored in #{var}/logbench/.

      Start as a background service:
        brew services start logbench
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
