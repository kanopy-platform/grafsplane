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
// +kubebuilder:defaultcompositionref:name=provisioneddatasources,enforced=true
type ProvisionedDataSource struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ProvisionedDataSourceSpec                  `json:"spec,omitempty"`
	Status xpapiext.CompositeResourceDefinitionStatus `json:"status,omitempty"`
}

// +kubebuilder:object:generate=true
type ProvisionedDataSourceSpec struct {
	// +kubebuilder:validation:Enum=proxy;direct
	AccessMode string `json:"accessMode,omitempty"`

	BasicAuth         *bool  `json:"basicAuth,omitempty"`
	BasicAuthUsername string `json:"basicAuthUsername,omitempty"`

	DatabaseName string `json:"databaseName,omitempty"`

	Default *bool `json:"default,omitempty"`

	// +kubebuilder:validation:Required
	Type string `json:"type,omitempty"`

	Config          string           `json:"config,omitempty"`
	SecureConfigRef *SecureConfigRef `json:"secureConfigRef,omitempty"`

	// +kubebuilder:validation:Required
	Name string `json:"name,omitempty"`

	// +kubebuilder:validation:Required
	Namespace string `json:"namespace,omitempty"`

	// +kubebuilder:validation:Required
	URL string `json:"url,omitempty"`
}

type SecureConfigRef struct {
	// +kubebuilder:validation:Required
	Key string `json:"key"`
	// +kubebuilder:validation:Required
	Name string `json:"name"`
	// +kubebuilder:validation:Required
	Namespace string `json:"namespace"`
}

// ProvisionedDataSourceList contains a list of ProvisionedDataSources.
// +kubebuilder:object:root=true
type ProvisionedDataSourceList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []ProvisionedDataSource `json:"items"`
}
