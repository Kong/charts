package ci_test

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
)

var (
	update = flag.Bool("update-golden", false, "update golden test output files")

	// Regexes that are to be used when pruning the output from content that expected to differ between every run.
	helmChartRegex        = regexp.MustCompile(`\s+helm.sh/chart:\s+.*`)
	tlsCrtOrKeyRegex      = regexp.MustCompile(`(tls\.)((\bcrt\b)|(\bkey\b)):.*`)
	caBundleRegex         = regexp.MustCompile(`(caBundle): .*`)
	postgresPasswordRegex = regexp.MustCompile(`(postgres-password): .*`)
)

// TestGolden goes through all *.yaml (helm values) files in this directory and `helm template` kong chart with those
// against various Kubernetes versions. The output for each is expected to be equal to the generated golden file stored
// under `./golden/{valuesFileName}_{kubeVersion}.golden.yaml`.
// When a difference in the output is expected, you can regenerate golden files by passing `-update-golden` flag while
// invoking this test.
func TestGolden(t *testing.T) {
	helm.AddRepo(t, &helm.Options{}, "bitnami", "https://charts.bitnami.com/bitnami")

	kubeVersions := []string{
		"v1.19.0",
		"v1.26.0",
		"v1.19.0-gke.125",
		"v1.26.0-gke.125",
	}

	for _, valuesFile := range getValuesYAMLFiles(t) {
		for _, kubeVersion := range kubeVersions {
			t.Run(fmt.Sprintf("%s_%s", valuesFile, kubeVersion), func(t *testing.T) {
				rendered := renderChartWithValues(t, kubeVersion, valuesFile)
				name := strings.Replace(valuesFile, ".yaml", "", 1)
				goldenFile := fmt.Sprintf("golden/%s_%s.golden.yaml", name, kubeVersion)

				if *update {
					t.Logf("updating golden file for %q", valuesFile)
					err := os.WriteFile(goldenFile, rendered, 0644)
					require.NoError(t, err, "could not write a golden file")
				}

				expected, err := os.ReadFile(goldenFile)
				require.NoError(t, err, "could not read a golden file")
				require.Equal(t, string(expected), string(rendered))
			})
		}
	}

}

func getValuesYAMLFiles(t *testing.T) []string {
	files, err := filepath.Glob("./*.yaml")
	require.NoError(t, err)
	return files
}

func renderChartWithValues(t *testing.T, kubeVersion string, valuesFile string) []byte {
	options := &helm.Options{
		KubectlOptions: k8s.NewKubectlOptions("", "", "test-namespace"),
		ValuesFiles:    []string{valuesFile},
	}

	// --kube-version injects Kubernetes version used for Capabilities.KubeVersion
	kubeVersionArgs := []string{"--kube-version", kubeVersion}
	const (
		chartDir    = "../"
		releaseName = "kong"
	)
	output := helm.RenderTemplate(t, options, chartDir, releaseName, nil, kubeVersionArgs...)
	return pruneContentExpectedToChange(output)
}

func pruneContentExpectedToChange(rendered string) (out []byte) {
	out = helmChartRegex.ReplaceAll([]byte(rendered), []byte(""))
	out = tlsCrtOrKeyRegex.ReplaceAll(out, []byte("$1$2: redacted"))
	out = caBundleRegex.ReplaceAll(out, []byte("$1: redacted"))
	return postgresPasswordRegex.ReplaceAll(out, []byte("$1: redacted"))
}
