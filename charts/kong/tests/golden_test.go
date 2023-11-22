package tests

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

// -update-golden flag can be passed to go test in order to regenerate golden manifests under testdata/golden.
var update = flag.Bool("update-golden", false, "update golden test output files")

// TestGolden goes through all test *-values.yaml (helm values) files in ci/ directory and `helm template` kong chart with those
// against various Kubernetes versions. The output for each is expected to be equal to the generated golden file stored
// under `./testdata/golden/<valuesFileName>_golden.yaml`.
// When a difference in the output is expected, you can regenerate golden files by passing `-update-golden` flag while
// invoking this test (or using `make test.golden.update`).
func TestGolden(t *testing.T) {
	helm.AddRepo(t, &helm.Options{}, "bitnami", "https://charts.bitnami.com/bitnami")
	_, err := helm.RunHelmCommandAndGetOutputE(t, &helm.Options{}, "dependencies", "build", "../", "--skip-refresh")
	require.NoError(t, err)

	for _, valuesFile := range getValuesYAMLFilesPaths(t) {
		t.Run(valuesFile, func(t *testing.T) {
			rendered := renderChartWithValues(t, valuesFile)
			goldenFile := goldenFilePath(valuesFile)

			if *update {
				t.Logf("updating golden file for %q", valuesFile)
				err := os.WriteFile(goldenFile, rendered, 0644)
				require.NoError(t, err, "could not write the golden file")
			}

			expected, err := os.ReadFile(goldenFile)
			require.NoError(t, err, "could not read the golden file")
			require.Equal(t, string(expected), string(rendered),
				"golden differs from the rendered manifest, if that's expected, run `make test.golden.update`")
		})
	}
}

// getValuesYAMLFilesPaths lists all the input values YAML files stored under ci/ directory as well as
// a default values.yaml.
func getValuesYAMLFilesPaths(t *testing.T) []string {
	files, err := filepath.Glob("../ci/*-values.yaml")
	require.NoError(t, err)

	// Append the default values.yaml as well.
	files = append(files, "../values.yaml")
	return files
}

// goldenFilePath builds a file path to the golden manifest render.
func goldenFilePath(valuesPath string) string {
	base := filepath.Base(valuesPath)
	base = strings.Replace(base, ".yaml", "", 1)
	return fmt.Sprintf("testdata/golden/%s_golden.yaml", base)
}

// renderChartWithValues renders the chart with value set from valuesFile.
func renderChartWithValues(t *testing.T, valuesFile string) []byte {
	options := &helm.Options{
		KubectlOptions: k8s.NewKubectlOptions("", "", "test-namespace"),
		ValuesFiles:    []string{valuesFile},
	}

	const (
		chartDir    = "../"
		releaseName = "kong"
	)
	output := helm.RenderTemplate(t, options, chartDir, releaseName, nil)
	return pruneContentExpectedToChange(output)
}

var (
	// Regexes that are to be used when pruning the output from content that expected to differ between every run.
	helmChartAnnotationRegex = regexp.MustCompile(`\s+helm.sh/chart:\s+.*`)
	tlsCrtOrKeyRegex         = regexp.MustCompile(`(tls\.)((\bcrt\b)|(\bkey\b)):.*`)
	caBundleRegex            = regexp.MustCompile(`(caBundle): .*`)
	postgresPasswordRegex    = regexp.MustCompile(`(postgres-password): .*`)
)

// pruneContentExpectedToChange replaces all the values that are expected to change between every single template render
// (certificates, passwords, etc.).
func pruneContentExpectedToChange(rendered string) (out []byte) {
	out = helmChartAnnotationRegex.ReplaceAll([]byte(rendered), []byte(""))
	out = tlsCrtOrKeyRegex.ReplaceAll(out, []byte("$1$2: redacted"))
	out = caBundleRegex.ReplaceAll(out, []byte("$1: redacted"))
	return postgresPasswordRegex.ReplaceAll(out, []byte("$1: redacted"))
}
