class Jenkins < Formula
  desc "Extendable open source continuous integration server"
  homepage "https://www.jenkins.io/"
  url "https://get.jenkins.io/war/2.418/jenkins.war"
  sha256 "7edc92816d30f8cef0241faa60c068f75ddf824152808b347007b9072df49191"
  license "MIT"

  livecheck do
    url "https://www.jenkins.io/download/"
    regex(%r{href=.*?/war/v?(\d+(?:\.\d+)+)/jenkins\.war}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, ventura:        "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, monterey:       "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, big_sur:        "aabfa9585c8cccd3bd5b8da2d1bedac9e4a63083caae8de826422b53cf107926"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "c01e59751cc7c16efa2844b6bdb2294c12d8a638f51a20a37391f347658226c9"
  end

  head do
    url "https://github.com/jenkinsci/jenkins.git", branch: "master"
    depends_on "maven" => :build
  end

  depends_on "openjdk@17"

  def install
    if build.head?
      system "mvn", "clean", "install", "-pl", "war", "-am", "-DskipTests"
    else
      system "#{Formula["openjdk@17"].opt_bin}/jar", "xvf", "jenkins.war"
    end
    libexec.install Dir["**/jenkins.war", "**/cli-#{version}.jar"]
    bin.write_jar_script libexec/"jenkins.war", "jenkins", java_version: "17"
    bin.write_jar_script libexec/"cli-#{version}.jar", "jenkins-cli", java_version: "17"

    (var/"log/jenkins").mkpath
  end

  def caveats
    <<~EOS
      Note: When using launchctl the port will be 8080.
    EOS
  end

  service do
    run [opt_bin/"jenkins", "--httpListenAddress=127.0.0.1", "--httpPort=8080"]
    keep_alive true
    log_path var/"log/jenkins/output.log"
    error_log_path var/"log/jenkins/error.log"
  end

  test do
    ENV["JENKINS_HOME"] = testpath
    ENV.prepend "_JAVA_OPTIONS", "-Djava.io.tmpdir=#{testpath}"

    port = free_port
    fork do
      exec "#{bin}/jenkins --httpPort=#{port}"
    end
    sleep 60

    output = shell_output("curl localhost:#{port}/")
    assert_match(/Welcome to Jenkins!|Unlock Jenkins|Authentication required/, output)
  end
end
