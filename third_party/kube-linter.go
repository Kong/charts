//go:build third_party
// +build third_party

package third_party

import _ "golang.stackrox.io/kube-linter/pkg/command/lint"

//go:generate go install -modfile go.mod golang.stackrox.io/kube-linter/cmd/kube-linter
