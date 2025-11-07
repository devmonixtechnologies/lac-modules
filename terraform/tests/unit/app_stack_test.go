package unit

import (
	"encoding/json"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestAppStackModulePlan(t *testing.T) {
	t.Parallel()

	if _, err := exec.LookPath("terraform"); err != nil {
		t.Skip("terraform binary not available in PATH; skipping app stack test")
	}

	terraformDir := filepath.Join("..", "fixtures", "app_stack")

	type variantCase struct {
		name                     string
		vars                     map[string]interface{}
		expectDashboardSnippet   string
		expectPolicyActions      []string
		expectPolicyResourceHint string
		expectFirehose           bool
	}

	variants := []variantCase{
		{
			name: "overview",
			vars: map[string]interface{}{
				"dashboard_template_variant": "overview",
			},
			expectDashboardSnippet: "CPUUtilization",
			expectPolicyActions:    []string{"lambda:InvokeFunction", "lambda:InvokeAsync"},
			expectPolicyResourceHint: "log-processor",
		},
		{
			name: "health",
			vars: map[string]interface{}{
				"dashboard_template_variant": "health",
				"dashboard_template_context": map[string]interface{}{
					"load_balancer_name": "app/test-alb",
				},
			},
			expectDashboardSnippet: "TargetResponseTime",
			expectPolicyActions:    []string{"lambda:InvokeFunction", "lambda:InvokeAsync"},
			expectPolicyResourceHint: "log-processor",
		},
		{
			name: "custom_path",
			vars: map[string]interface{}{
				"dashboard_template_path": filepath.Join("..", "fixtures", "app_stack", "custom_dashboard.json"),
			},
			expectDashboardSnippet: "CustomWidgetMetric",
			expectPolicyActions:    []string{"lambda:InvokeFunction", "lambda:InvokeAsync"},
			expectPolicyResourceHint: "log-processor",
		},
		{
			name: "firehose",
			vars: map[string]interface{}{
				"dashboard_template_variant": "overview",
				"log_subscription_destination_arn": "",
				"log_subscription_role_policy_statements": []map[string]interface{}{},
				"create_log_processor_lambda": false,
				"create_log_processor_firehose": true,
				"log_processor_firehose_config": map[string]interface{}{
					"stream_name":   "test-firehose-logs",
					"s3_bucket_arn": "arn:aws:s3:::test-firehose-bucket",
				},
			},
			expectDashboardSnippet:   "CPUUtilization",
			expectPolicyActions:      []string{"firehose:PutRecord", "firehose:PutRecordBatch"},
			expectPolicyResourceHint: "test-firehose-logs",
			expectFirehose:           true,
		},
	}

	baseEnvVars := map[string]string{
		"AWS_ACCESS_KEY_ID":     "mock",
		"AWS_SECRET_ACCESS_KEY": "mock",
		"AWS_DEFAULT_REGION":    "us-east-1",
	}

	for _, tc := range variants {
		t.Run(tc.name, func(t *testing.T) {
			planFilePath := filepath.Join(t.TempDir(), "plan.out")

			opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    terraformDir,
				PlanFilePath:    planFilePath,
				TerraformBinary: "terraform",
				EnvVars:        baseEnvVars,
				Vars:           tc.vars,
				NoColor:        true,
				Logger:         logger.Discard,
			})

			plan := terraform.InitAndPlanAndShowWithStruct(t, opts)

			require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.ecs_service.aws_ecs_service.this")
			require.Equal(t, []string{"create"}, plan.ResourceChangesMap["module.app_stack.module.ecs_service.aws_ecs_service.this"].Change.Actions)
			require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.application_log_group.aws_cloudwatch_log_group.this")
			require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.service_dashboard[0].aws_cloudwatch_dashboard.this")
			require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.application_log_group.aws_iam_role.subscription[0]")
			require.Equal(t, []string{"create"}, plan.ResourceChangesMap["module.app_stack.module.application_log_group.aws_iam_role.subscription[0]"].Change.Actions)
			require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.application_log_group.aws_iam_role_policy.subscription[0]")

			if tc.expectFirehose {
				require.Contains(t, plan.ResourceChangesMap, "module.app_stack.module.log_processor_firehose[0].aws_kinesis_firehose_delivery_stream.this")
			}

			policyChange := plan.ResourceChangesMap["module.app_stack.module.application_log_group.aws_iam_role_policy.subscription[0]"]
			afterMap, ok := policyChange.Change.After.(map[string]interface{})
			require.True(t, ok, "expected change.after to be a map")
			policyJSON, ok := afterMap["policy"].(string)
			require.True(t, ok, "expected policy attribute to be string")

			type policyDocument struct {
				Statement []struct {
					Action   interface{} `json:"Action"`
					Resource interface{} `json:"Resource"`
				} `json:"Statement"`
			}

			var doc policyDocument
			require.NoError(t, json.Unmarshal([]byte(policyJSON), &doc))
			require.NotEmpty(t, doc.Statement, "policy must contain statements")

			var actions []string
			var resources []string
			for _, stmt := range doc.Statement {
				switch v := stmt.Action.(type) {
				case []interface{}:
					for _, a := range v {
						aStr, ok := a.(string)
						require.True(t, ok)
						actions = append(actions, aStr)
					}
				case string:
					actions = append(actions, v)
				}

				switch v := stmt.Resource.(type) {
				case []interface{}:
					for _, r := range v {
						rStr, ok := r.(string)
						require.True(t, ok)
						resources = append(resources, rStr)
					}
				case string:
					resources = append(resources, v)
				}
			}

			require.Subset(t, actions, tc.expectPolicyActions)
			matchedResource := false
			for _, r := range resources {
				if strings.Contains(r, tc.expectPolicyResourceHint) {
					matchedResource = true
					break
				}
			}
			require.True(t, matchedResource, "expected policy resource to contain %s", tc.expectPolicyResourceHint)

			dashboardChange := plan.ResourceChangesMap["module.app_stack.module.service_dashboard[0].aws_cloudwatch_dashboard.this"]
			dashboardAfter, ok := dashboardChange.Change.After.(map[string]interface{})
			require.True(t, ok)
			dashboardBody, ok := dashboardAfter["dashboard_body"].(string)
			require.True(t, ok)
			require.Contains(t, dashboardBody, tc.expectDashboardSnippet)
		})
	}
}
