package exoscale

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestCloneMachine(t *testing.T) {
	testName := "foo"
	testSize := "small"
	testESCap := 1

	type tfvarsPart struct {
		nameSlice []string
		sizeMap   map[string]string
		esCapMap  map[string]int
	}

	cluster := Default(-1, "testName")

	cluster.tfvars.MasterNamesSC = []string{testName}
	cluster.tfvars.MasterNameSizeMapSC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNamesSC = []string{testName}
	cluster.tfvars.WorkerNameSizeMapSC = map[string]string{testName: testSize}
	cluster.tfvars.ESLocalStorageCapacityMapSC = map[string]int{testName: testESCap}
	cluster.tfvars.MasterNamesWC = []string{testName}
	cluster.tfvars.MasterNameSizeMapWC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNamesWC = []string{testName}
	cluster.tfvars.WorkerNameSizeMapWC = map[string]string{testName: testSize}
	cluster.tfvars.ESLocalStorageCapacityMapWC = map[string]int{testName: testESCap}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker} {
			if _, err := cluster.CloneMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while cloning %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	for machineType, part := range map[string]tfvarsPart{
		"sc master": {
			cluster.tfvars.MasterNamesSC,
			cluster.tfvars.MasterNameSizeMapSC,
			nil,
		},
		"sc worker": {
			cluster.tfvars.WorkerNamesSC,
			cluster.tfvars.WorkerNameSizeMapSC,
			cluster.tfvars.ESLocalStorageCapacityMapSC,
		},
		"wc master": {
			cluster.tfvars.MasterNamesWC,
			cluster.tfvars.MasterNameSizeMapWC,
			nil,
		},
		"wc worker": {
			cluster.tfvars.WorkerNamesWC,
			cluster.tfvars.WorkerNameSizeMapWC,
			cluster.tfvars.ESLocalStorageCapacityMapWC,
		},
	} {
		if len(part.nameSlice) != 2 {
			t.Errorf("%s machine not cloned in name slice", machineType)
		}
		if len(part.sizeMap) != 2 {
			t.Errorf("%s machine not cloned in size map", machineType)
		}
		for _, size := range part.sizeMap {
			if size != testSize {
				t.Errorf(
					"%s size mismatch, want: %s, got: %s",
					machineType, part.sizeMap[testName], size,
				)
			}
		}
		if part.esCapMap != nil {
			if len(part.esCapMap) != 2 {
				t.Errorf("%s not cloned in es capacity map", machineType)
			}
			for _, esCap := range part.esCapMap {
				if esCap != testESCap {
					t.Errorf(
						"%s es capacity mismatch, want: %d, got: %d",
						machineType, part.esCapMap[testName], esCap,
					)
				}
			}
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := Default(-1, "testName"), Default(-1, "testName")

	got.tfvars = ExoscaleTFVars{
		MasterNamesSC:               []string{testName},
		MasterNameSizeMapSC:         map[string]string{testName: "a"},
		WorkerNamesSC:               []string{testName},
		WorkerNameSizeMapSC:         map[string]string{testName: "a"},
		ESLocalStorageCapacityMapSC: map[string]int{testName: 1},
		MasterNamesWC:               []string{testName},
		MasterNameSizeMapWC:         map[string]string{testName: "a"},
		WorkerNamesWC:               []string{testName},
		WorkerNameSizeMapWC:         map[string]string{testName: "a"},
		ESLocalStorageCapacityMapWC: map[string]int{testName: 1},
	}

	want.tfvars = ExoscaleTFVars{
		MasterNamesSC:               []string{},
		MasterNameSizeMapSC:         map[string]string{},
		WorkerNamesSC:               []string{},
		WorkerNameSizeMapSC:         map[string]string{},
		ESLocalStorageCapacityMapSC: map[string]int{},
		MasterNamesWC:               []string{},
		MasterNameSizeMapWC:         map[string]string{},
		WorkerNamesWC:               []string{},
		WorkerNameSizeMapWC:         map[string]string{},
		ESLocalStorageCapacityMapWC: map[string]int{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker} {
			if err := got.RemoveMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while removing %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	if diff := cmp.Diff(want.tfvars, got.tfvars); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
