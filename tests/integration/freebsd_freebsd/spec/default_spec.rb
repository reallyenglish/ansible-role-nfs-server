require "spec_helper"

class ServiceNotReady < StandardError
end

sleep 10 if ENV["JENKINS_HOME"]

context "after provisioning finished" do
  describe server(:client1) do
    it "should be able to ping server" do
      result = current_server.ssh_exec("ping -c 1 #{server(:server1).server.address} && echo OK")
      expect(result).to match(/OK/)
    end
  end

  describe server(:server1) do
    it "should be able to ping client" do
      result = current_server.ssh_exec("ping -c 1 #{server(:client1).server.address} && echo OK")
      expect(result).to match(/OK/)
    end
  end

  describe server(:client1) do
    it "finds a file, /exports/ro/foo" do
      r = current_server.ssh_exec("ls /exports/ro/foo")
      expect(r).to match(%r{\/exports\/ro\/foo})
    end

    it "creates a file, /exports/rw/bar" do
      current_server.ssh_exec("touch /exports/rw/bar")
      r = current_server.ssh_exec("ls /exports/rw/bar")
      expect(r).to match(%r{\/exports\/rw\/bar})
    end
  end
end
