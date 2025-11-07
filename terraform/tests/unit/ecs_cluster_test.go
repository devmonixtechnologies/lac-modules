package unit

import (
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestECSClusterModule(t *testing.T) {
	t.Parallel()

	if _, err := exec.LookPath("terraform"); err != nil {
		t.Skip("terraform binary not available in PATH; skipping module test")
	}

	terraformDir := filepath.Join("..", "fixtures", "ecs_cluster")
	planFilePath := filepath.Join(t.TempDir(), "plan.out")

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		PlanFilePath: planFilePath,
		TerraformBinary: "terraform",
		EnvVars: map[string]string{
			"AWS_ACCESS_KEY_ID":     "mock",
			"AWS_SECRET_ACCESS_KEY": "mock",
			"AWS_DEFAULT_REGION":   "us-east-1",
		},
		NoColor: true,
		Logger:  logger.Discard,
	})

	plan := terraform.InitAndPlanAndShowWithStruct(t, opts)
	require.Contains(t, plan.ResourceChangesMap, "module.ecs_cluster.aws_ecs_cluster.this")
	require.Equal(t, []string{"create"}, plan.ResourceChangesMap["module.ecs_cluster.aws_ecs_cluster.this"].Change.Actions)
}
