require "spec_helper"
require "serverspec"

rpc_service = "rpcbind"
exports = "/etc/exports"
ports = [2049, 111]
default_user = "root"
default_group = "root"

case os[:family]
when "freebsd"
  default_group = "wheel"
end

describe file(exports) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/#{Regexp.escape("/usr/local")}\s+#{Regexp.escape("-network 192.168.1.0/24")}/) }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/mountd") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^mountd_flags="-r"$/) }
  end

  describe file("/etc/rc.conf.d/nfsd") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    # XXX you cannot use service("nfs_server") because such service does not exist
    its(:content) { should match(/^nfs_server_enable="YES"$/) }
    its(:content) { should match(/^nfs_server_flags="-n 4"$/) }
  end

  describe file("/etc/rc.conf.d/rpcbind") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^rpcbind_flags="-h 10\.0\.2\.15"$/) }
  end

  describe service("nfsd") do
    it { should be_enabled }
    it { should be_running }
  end

  describe service(rpc_service) do
    it { should be_running }
    it { should be_enabled }
  end

  describe service("mountd") do
    it { should be_enabled }
    it { should be_running }
  end

  describe command("rpcinfo -s | awk '{ print $4 }'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/mountd/) }
    its(:stdout) { should match(/rpcbind/) }
    its(:stdout) { should match(/nfs/) }
  end

  describe command("mount") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/#{Regexp.escape("/dev/da0p2 on / (ufs, NFS exported, local, journaled soft-updates)")}/) }
    its(:stderr) { should eq "" }
  end
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
