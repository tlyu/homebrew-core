class Eksctl < Formula
  desc "Simple command-line tool for creating clusters on Amazon EKS"
  homepage "https://eksctl.io"
  url "https://github.com/weaveworks/eksctl.git",
      tag:      "0.126.0",
      revision: "299cbb7efb01c5d5adb82bbc6ce6904b8c081413"
  license "Apache-2.0"
  head "https://github.com/weaveworks/eksctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "4d226377920687d55defd6a176e6bac8aab667bda6d434f77ae652b85049dd26"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "c43aacc74d5bf83535205cb424be5a01e877817ffe55835bd78c910d1f514f1e"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "1fe8324232760161971f2ff118bd2a3a5d6dad8f4debacad7cd23566cb79e991"
    sha256 cellar: :any_skip_relocation, ventura:        "bc9666acf319a7ac4f20d514c1df664717927c06255cca7024f30a6eaed7fba7"
    sha256 cellar: :any_skip_relocation, monterey:       "9fcd76c4f84c531f4d58534f59e60febfaed16d678df63245c05973c4b30f104"
    sha256 cellar: :any_skip_relocation, big_sur:        "0639f709dee5215fe113251c5b1a94972569b1d31f723735c29df06d364af9ee"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4f8af0d383ebedbecbb4f2c571461baa7139131687c8ace609f5de78f07aac22"
  end

  depends_on "counterfeiter" => :build
  depends_on "go" => :build
  depends_on "go-bindata" => :build
  depends_on "mockery" => :build
  depends_on "aws-iam-authenticator"

  # Eksctl requires newer version of ifacemaker
  #
  # Replace with `depends_on "ifacemaker" => :build` when ifacemaker > 1.2.0
  # Until then get the resource version from go.mod
  resource "ifacemaker" do
    url "https://github.com/vburenin/ifacemaker/archive/b2018d8549dc4d51ce7e2254d6b0a743643613be.tar.gz"
    sha256 "41888bf97133b4e7e190f2040378661b5bcab290d009e1098efbcb9db0f1d82f"
  end

  def install
    resource("ifacemaker").stage do
      system "go", "build", *std_go_args(ldflags: "-s -w", output: buildpath/"ifacemaker")
    end
    inreplace "build/scripts/generate-aws-interfaces.sh", "${GOBIN}/ifacemaker",
                                                          buildpath/"ifacemaker"

    ENV["GOBIN"] = HOMEBREW_PREFIX/"bin"
    ENV.deparallelize # Makefile prerequisites need to be run in order
    system "make", "build"
    bin.install "eksctl"

    generate_completions_from_executable(bin/"eksctl", "completion")
  end

  test do
    assert_match "The official CLI for Amazon EKS",
      shell_output("#{bin}/eksctl --help")

    assert_match "Error: couldn't create node group filter from command line options: --cluster must be set",
      shell_output("#{bin}/eksctl create nodegroup 2>&1", 1)
  end
end
