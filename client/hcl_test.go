package client

import (
	"io/ioutil"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/aws"
	"github.com/elastisys/ck8s/api/citycloud"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/safespring"
)

var roundTripTests = map[string]interface{}{
	// TODO: clusterType
	"testdata/exoscale.tfvars":               exoscale.Default(api.ServiceCluster, "testName").TFVars(),
	"testdata/safespring.tfvars":             safespring.Default(api.ServiceCluster, "testName").TFVars(),
	"testdata/citycloud.tfvars":              citycloud.Default(api.ServiceCluster, "testName").TFVars(),
	"testdata/aws.tfvars":                    aws.Default(api.ServiceCluster, "testName").TFVars(),
	"testdata/exoscale-backend-config.hcl":   exoscale.NewCloudProvider().TerraformBackendConfig(),
	"testdata/safespring-backend-config.hcl": safespring.NewCloudProvider().TerraformBackendConfig(),
	"testdata/citycloud-backend-config.hcl":  citycloud.NewCloudProvider().TerraformBackendConfig(),
	"testdata/aws-backend-config.hcl":        aws.NewCloudProvider().TerraformBackendConfig(),
}

func TestHCLRoundTrip(t *testing.T) {
	for path, data := range roundTripTests {
		input, err := ioutil.ReadFile(path)
		if err != nil {
			t.Fatalf("error reading test data (%s): %s", path, err)
		}

		if err := hclDecode(input, data); err != nil {
			t.Fatalf("error parsing hcl (%s): %s", path, err)
		}

		output := hclEncode(data)

		if diff := cmp.Diff(input, output); diff != "" {
			t.Errorf("%s mismatch (-input +output):\n%s", path, diff)
		}
	}
}
