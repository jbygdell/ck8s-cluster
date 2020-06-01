package runner

import (
	"encoding/json"
	"errors"
	"io"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var TerraformPlanDiffErr = errors.New("terraform plan has diff")

type TerraformConfig struct {
	Path              string
	Workspace         string
	DataDirPath       string
	BackendConfigPath string
	TFVarsPath        string

	// TODO: If we switch over to a single cluster implementation target should
	//		 become unnecessary.
	Target string

	// TODO: We should try to get rid of this.
	Env map[string]string
}

func (c *TerraformConfig) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("path", c.Path)
	enc.AddString("workspace", c.Workspace)
	enc.AddString("data_dir", c.DataDirPath)
	enc.AddString("backend_config", c.BackendConfigPath)
	enc.AddString("tfvars", c.TFVarsPath)
	return nil
}

type Terraform struct {
	runner Runner

	config *TerraformConfig

	logger *zap.Logger
}

func NewTerraform(
	logger *zap.Logger,
	runner Runner,
	config *TerraformConfig,
) *Terraform {
	return &Terraform{
		runner: runner,

		config: config,

		logger: logger.With(
			zap.Object("config", config),
		),
	}
}

func (t *Terraform) command(args ...string) *Command {
	cmd := NewCommand("terraform", args...)

	cmd.Env = t.config.Env
	cmd.Env["TF_DATA_DIR"] = t.config.DataDirPath
	cmd.Env["TF_WORKSPACE"] = t.config.Workspace

	// Some Terraform commands allows you to supply the configuration path as
	// an argument, some don't. For now let's change working directory for the
	// command. It shouldn't matter as long as we don't share instances.
	// If we ever want to control multiple Terraform configuration paths
	// with the same command instance see:
	// https://github.com/hashicorp/terraform/issues/15761
	// https://github.com/hashicorp/terraform/issues/15581
	// https://github.com/hashicorp/terraform/issues/15934
	// https://github.com/hashicorp/terraform/issues/17300
	cmd.Dir = t.config.Path

	return cmd
}

// Init runs `terraform init -backend-config BACKEND_CONFIG_PATH`
func (t *Terraform) Init() error {
	t.logger.Debug("terraform_init")
	return t.runner.Background(t.command(
		"init", "-backend-config", t.config.BackendConfigPath,
	))
}

// HasNoDiff runs `terraform plan -var-file TFVARS_PATH -target TARGET
// -detailed-exitcode` and returns an error of type TerraformPlanDiffErr if it
// has a diff.
func (t *Terraform) PlanNoDiff() error {
	t.logger.Debug("terraform_plan_no_diff")

	cmd := t.command(
		"plan",
		"-var-file", t.config.TFVarsPath,
		"-target", t.config.Target,
		"-detailed-exitcode",
	)

	cmd.ExitCodeHandlers[2] = func() error {
		return TerraformPlanDiffErr
	}

	return t.runner.Run(cmd)
}

// Apply runs `terraform apply -var-file TFVARS_PATH -target TARGET` with the
// -auto-approve flag if autoApprove is true. If autoApprove is false it
// always outputs to allow for interactive input.
func (t *Terraform) Apply(autoApprove bool) error {
	t.logger.Debug("terraform_apply")

	args := []string{
		"apply",
		"-var-file", t.config.TFVarsPath,
		"-target", t.config.Target,
	}
	if autoApprove {
		args = append(args, "-auto-approve")
	}

	cmd := t.command(args...)

	if !autoApprove {
		return t.runner.Output(cmd)
	}

	return t.runner.Run(cmd)
}

// Output runs `terraform output -json` in the background and stores the output
// in the output value.
func (t *Terraform) Output(output interface{}) error {
	t.logger.Debug("terraform_output")

	cmd := t.command("output", "-json")

	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		return json.NewDecoder(stdout).Decode(&output)
	}

	return t.runner.Background(cmd)
}