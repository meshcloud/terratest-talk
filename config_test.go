package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var gcpProject string = "terratest-talk"
var instanceName string = "public-1"

func TestConfig(t *testing.T) {
	t.Parallel()

	tfOptions := &terraform.Options{
		TerraformDir: "./terraform/config_test",
	}

	t.Cleanup(func() {
		terraform.Destroy(t, tfOptions)
	})

	terraform.InitAndApply(t, tfOptions)

	pubVM := gcp.FetchInstance(t, gcpProject, instanceName)
	keyPair := ssh.GenerateRSAKeyPair(t, 2048)
	pubVM.AddSshKey(t, "terratest", keyPair.PublicKey)
	host := ssh.Host{
		Hostname:    terraform.Output(t, tfOptions, "public_ip"),
		SshUserName: "terratest",
		SshKeyPair:  keyPair,
	}
	// we have to wait for AddSshkey to finish. Don't do this in production!
	time.Sleep(3 * time.Second)

	// Check that we can access transit
	_, err := ssh.CheckSshCommandE(t, host, "ping -c 3 10.0.1.2")
	if err != nil {
		t.Fatalf("Could not connect to transit from public: '%v'", err)
	}

	// Check that we cannot access private
	_, err = ssh.CheckSshCommandE(t, host, "ping -c 3 10.0.2.2")
	if err == nil {
		t.Fatalf("Could connect to private from public, which is not allowed")
	}

}
