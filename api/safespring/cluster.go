package safespring

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

// Cluster TODO
type Cluster struct {
	config openstack.OpenstackConfig
	secret openstack.OpenstackSecret
	tfvars SafespringTFVars
}

// Config TODO
func (e *Cluster) Config() interface{} {
	return &e.config
}

// Secret TODO
func (e *Cluster) Secret() interface{} {
	return &e.secret
}

// TFVars TODO
func (e *Cluster) TFVars() interface{} {
	return &e.tfvars
}

func (e *Cluster) CloudProvider() api.CloudProviderType {
	return e.config.CloudProviderType
}

func (e *Cluster) CloudProviderVars(state api.ClusterState) interface{} {
	return nil
}

func (e *Cluster) Name() string {
	switch e.config.ClusterType {
	case api.ServiceCluster:
		if e.tfvars.PrefixSC != "" {
			return e.tfvars.PrefixSC
		}
	case api.WorkloadCluster:
		if e.tfvars.PrefixWC != "" {
			return e.tfvars.PrefixWC
		}
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.config.ClusterType))
	}

	return api.NameHelper(&e.config.BaseConfig)
}

// State TODO
func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := terraformOutput{
		TerraformOutput: openstack.StateHelper(
			e.config.ClusterType,
			e.Name(),
		),
	}

	return &tfOutput, loadState(&tfOutput)
}

func (e *Cluster) S3Buckets() map[string]string {
	return api.S3BucketsHelper(&e.config.BaseConfig)
}

func (e *Cluster) TerraformWorkspace() string {
	return e.config.EnvironmentName
}

func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	return openstack.TerraformEnvHelper(e.config, e.secret, sshPublicKey)
}

func (e *Cluster) AnsibleEnv() map[string]string {
	return openstack.AnsibleEnvHelper(e.config, e.secret)
}
