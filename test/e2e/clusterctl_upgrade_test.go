//go:build e2e
// +build e2e

/*
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package e2e

import (
	"fmt"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	"k8s.io/utils/ptr"
	capi_e2e "sigs.k8s.io/cluster-api/test/e2e"
)

var (
	clusterctlDownloadURL = "https://github.com/kubernetes-sigs/cluster-api/releases/download/v%s/clusterctl-{OS}-{ARCH}"
	providerCAPIPrefix    = "cluster-api:v%s"
	providerKThreesPrefix = "k3s:v%s"
	providerDockerPrefix  = "docker:v%s"
)

var _ = Describe("When testing clusterctl upgrades using ClusterClass (v0.2.0=>current) [ClusterClass]", func() {
	// Upgrade from v0.2.0 to current (current version is built from src).
	version := "v0.2.0"
	k3sCapiUpgradedVersion := e2eConfig.GetVariable(K3sCapiCurrentVersion)
	capiCoreVersion := e2eConfig.GetVariable(CapiCoreVersion)
	capi_e2e.ClusterctlUpgradeSpec(ctx, func() capi_e2e.ClusterctlUpgradeSpecInput {
		return capi_e2e.ClusterctlUpgradeSpecInput{
			E2EConfig:                       e2eConfig,
			ClusterctlConfigPath:            clusterctlConfigPath,
			BootstrapClusterProxy:           bootstrapClusterProxy,
			ArtifactFolder:                  artifactFolder,
			SkipCleanup:                     skipCleanup,
			InfrastructureProvider:          ptr.To("docker"),
			InitWithBinary:                  fmt.Sprintf(clusterctlDownloadURL, capiCoreVersion),
			InitWithCoreProvider:            fmt.Sprintf(providerCAPIPrefix, capiCoreVersion),
			InitWithBootstrapProviders:      []string{fmt.Sprintf(providerKThreesPrefix, version)},
			InitWithControlPlaneProviders:   []string{fmt.Sprintf(providerKThreesPrefix, version)},
			InitWithInfrastructureProviders: []string{fmt.Sprintf(providerDockerPrefix, capiCoreVersion)},
			InitWithProvidersContract:       "v1beta1",
			// InitWithKubernetesVersion is for the management cluster, WorkloadKubernetesVersion is for the workload cluster.
			// Hardcoding the versions as later versions of k3s might not be compatible with the older versions of CAPI k3s.
			InitWithKubernetesVersion:   "v1.30.0",
			WorkloadKubernetesVersion:   "v1.30.2+k3s2",
			MgmtFlavor:                  "topology",
			WorkloadFlavor:              "topology",
			UseKindForManagementCluster: true,
			// Configuration for the provider upgrades.
			Upgrades: []ClusterctlUpgradeSpecInputUpgrade{
				{
					// Upgrade to current.
					BootstrapProviders:    []string{fmt.Sprintf(providerKThreesPrefix, k3sCapiUpgradedVersion)},
					ControlPlaneProviders: []string{fmt.Sprintf(providerKThreesPrefix, k3sCapiUpgradedVersion)},
				},
			},
		}
	})
})
