// +groupName=grafana.kanopy-platform.github.io
// +versionName=v1beta1
// +kubebuilder:validation:Optional
package v1beta1

import (
	xpapiext "github.com/crossplane/crossplane/apis/apiextensions/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// infrastructure resources.
// +kubebuilder:object:root=true
// +kubebuilder:printcolumn:name="ESTABLISHED",type="string",JSONPath=".status.conditions[?(@.type=='Established')].status"
// +kubebuilder:printcolumn:name="OFFERED",type="string",JSONPath=".status.conditions[?(@.type=='Offered')].status"
// +kubebuilder:printcolumn:name="AGE",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:storageversion
// +kubebuilder:resource:scope=Cluster,categories=crossplane,shortName=xrd;xrds
// +kubebuilder:defaultcompositionref:name=provisioneddashboards,enforced=true
type ProvisionedDashboard struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ProvisionedDashboardSpec                   `json:"spec,omitempty"`
	Status xpapiext.CompositeResourceDefinitionStatus `json:"status,omitempty"`
}

type ProvisionedDashboardSpec struct {
	FolderID string `json:"folderID,omitempty"`

	// +kubebuilder:validation:Required
	Config string `json:"config,omitempty"`
	// +kubebuilder:validation:Required
	OrgID string `json:"orgID,omitempty"`
}
