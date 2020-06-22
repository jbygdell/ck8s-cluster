package safespring

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

const (
	// FlavorMinimum TODO
	FlavorMinimum api.ClusterFlavor = "minimum"

	// FlavorHA TODO
	FlavorHA api.ClusterFlavor = "ha"
)

// Default TODO
func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	return &Cluster{
		config: openstack.OpenstackConfig{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				api.Safespring,
				clusterName,
			),

			S3RegionAddress: "s3.sto1.safedc.net",
		},
		secret: openstack.OpenstackSecret{},
	}
}

// Minimum TODO
func Minimum(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}

// HA TODO
func HA(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
