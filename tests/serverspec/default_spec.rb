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
when "openbsd"
  default_group = "wheel"
end

describe file(exports) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  case os[:family]
  when "freebsd", "openbsd"
    its(:content) { should match(/#{Regexp.escape("/usr/local")}\s+#{Regexp.escape("-network 192.168.1.0/24")}/) }
  else
    its(:content) { should match(/#{Regexp.escape("/usr/local")}\s+#{Regexp.escape("192.168.1.0/24")}/) }
  end
end

case os[:family]
when "openbsd"
  describe file("/etc/rc.conf.local") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^mountd_flags=#{Regexp.escape("/etc/exports")}$/) }
    its(:content) { should match(/^nfsd_flags=-tun 5$/) }
  end
  describe service("nfsd") do
    it { should be_enabled }
    it { should be_running }
  end

  describe service("portmap") do
    it { should be_enabled }
    it { should be_running }
  end

  describe service("mountd") do
    it { should be_enabled }
    it { should be_running }
  end

  describe command("rpcinfo -p localhost") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/portmapper/) }
    its(:stdout) { should match(/nfs/) }
    its(:stdout) { should match(/mountd/) }
  end
when "ubuntu"
  describe package("nfs-kernel-server") do
    it { should be_installed }
  end
  describe file("/etc/default/nfs-common") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^STATDOPTS=""$/) }
    its(:content) { should match(/^NEED_GSSD=""$/) }
  end

  describe file("/etc/default/nfs-kernel-server") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^RPCNFSDCOUNT="4"$/) }
    its(:content) { should match(/^RPCNFSDPRIORITY="0"$/) }
    its(:content) { should match(/^RPCMOUNTDOPTS="--manage-gids"$/) }
    its(:content) { should match(/^NEED_SVCGSSD=""$/) }
    its(:content) { should match(/^RPCSVCGSSDOPTS=""$/) }
    its(:content) { should match(/^RPCNFSDOPTS=""$/) }
  end

  if os[:release].to_f >= 16.04
    describe service("nfs-mountd") do
      it { should be_running }
      it { should be_enabled }
    end
  else
    describe command("service nfs-kernel-server status") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/nfsd running/) }
      its(:stderr) { should eq "" }
    end

    describe process("rpc.mountd") do
      it { should be_running }
    end

    describe command("rpcinfo -s  | awk '{ print $4 }'") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/portmapper/) }
      its(:stdout) { should match(/nlockmgr/) }
      its(:stdout) { should match(/mountd/) }
      its(:stdout) { should match(/nfs/) }
      its(:stderr) { should eq "" }
    end
  end
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
    its(:content) { should match(/^nfs_server_flags="-tun 5"$/) }
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
