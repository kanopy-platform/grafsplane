// +groupName=grafana.kanopy-platform.github.io
// +versionName=v1beta1
// +kubebuilder:validation:Optional
package v1beta1

import (
	xpapiext "github.com/crossplane/crossplane/apis/apiextensions/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Grafana Folder resource.
// +kubebuilder:object:root=true
// +kubebuilder:printcolumn:name="ESTABLISHED",type="string",JSONPath=".status.conditions[?(@.type=='Established')].status"
// +kubebuilder:printcolumn:name="OFFERED",type="string",JSONPath=".status.conditions[?(@.type=='Offered')].status"
// +kubebuilder:printcolumn:name="AGE",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:storageversion
// +kubebuilder:resource:scope=Cluster,categories=crossplane,shortName=xrd;xrds
// +kubebuilder:defaultcompositionref:name=provisionedfolders,enforced=true
type ProvisionedFolder struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ProvisionedFolderSpec                      `json:"spec,omitempty"`
	Status xpapiext.CompositeResourceDefinitionStatus `json:"status,omitempty"`
}

type ProvisionedFolderSpec struct {
	// +kubebuilder:validation:Required
	FolderTitle string `json:"folderTitle,omitempty"`
	// +kubebuilder:validation:Optional
	DeletionPolicy string `json:"deletionPolicy,omitempty"`
	// +kubebuilder:validation:Required
	ProviderConfigName string `json:"providerConfigName,omitempty"`
}
