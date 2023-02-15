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

// -update-golden flag can be passed to go test in order to regenerate golden manifests under testdata/golden.
var update = flag.Bool("update-golden", false, "update golden test output files")

// TestGolden goes through all *.yaml (helm values) files in this directory and `helm template` kong chart with those
// against various Kubernetes versions. The output for each is expected to be equal to the generated golden file stored
// under `./golden/{valuesFileName}_{kubeVersion}.golden.yaml`.
// When a difference in the output is expected, you can regenerate golden files by passing `-update-golden` flag while
// invoking this test.
func TestGolden(t *testing.T) {
    helm.AddRepo(t, &helm.Options{}, "bitnami", "https://charts.bitnami.com/bitnami")

    // Test against the lowest and the highest Kubernetes version we claim as supported in
    // https://docs.konghq.com/kubernetes-ingress-controller/latest/references/version-compatibility/.
    kubeVersions := []string{
        "v1.22.0",
        "v1.26.0",
    }

    for _, valuesFile := range getValuesYAMLFilesPaths(t) {
        for _, kubeVersion := range kubeVersions {
            t.Run(fmt.Sprintf("%s_%s", valuesFile, kubeVersion), func(t *testing.T) {
                rendered := renderChartWithValues(t, kubeVersion, valuesFile)
                goldenFile := goldenFilePath(valuesFile, kubeVersion)

                if *update {
                    t.Logf("updating golden file for %q", valuesFile)
                    err := os.WriteFile(goldenFile, rendered, 0644)
                    require.NoError(t, err, "could not write a golden file")
                }

                expected, err := os.ReadFile(goldenFile)
                require.NoError(t, err, "could not read a golden file")
                require.Equal(t, string(expected), string(rendered),
                    "golden differs from the rendered manifest, if that's expected, run `make generate`")
            })
        }
    }
}

// getValuesYAMLFilesPaths lists all the input values YAML files stored under testdata/values directory as well as
// a default values.yaml.
func getValuesYAMLFilesPaths(t *testing.T) []string {
    files, err := filepath.Glob("testdata/values/*.yaml")
    require.NoError(t, err)

    // Append also the default values.yaml
    files = append(files, "../values.yaml")
    return files
}

// goldenFilePath builds a file path to the golden manifest render.
func goldenFilePath(valuesPath, kubeVersion string) string {
    base := filepath.Base(valuesPath)
    base = strings.Replace(base, ".yaml", "", 1)
    return fmt.Sprintf("testdata/golden/%s_%s.yaml", base, kubeVersion)
}

// renderChartWithValues renders the chart with value set from valuesFile.
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

var (
    // Regexes that are to be used when pruning the output from content that expected to differ between every run.
    helmChartRegex        = regexp.MustCompile(`\s+helm.sh/chart:\s+.*`)
    tlsCrtOrKeyRegex      = regexp.MustCompile(`(tls\.)((\bcrt\b)|(\bkey\b)):.*`)
    caBundleRegex         = regexp.MustCompile(`(caBundle): .*`)
    postgresPasswordRegex = regexp.MustCompile(`(postgres-password): .*`)
)

// pruneContentExpectedToChange replaces all the values that are expected to change between every single template render
// (certificates, passwords, etc.).
func pruneContentExpectedToChange(rendered string) (out []byte) {
    out = helmChartRegex.ReplaceAll([]byte(rendered), []byte(""))
    out = tlsCrtOrKeyRegex.ReplaceAll(out, []byte("$1$2: redacted"))
    out = caBundleRegex.ReplaceAll(out, []byte("$1: redacted"))
    return postgresPasswordRegex.ReplaceAll(out, []byte("$1: redacted"))
}
