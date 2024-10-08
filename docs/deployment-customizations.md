# Deployment Customizations

On this page are various deployment customizations and their corresponding input variables that you may set to meet your requirements.

## Load Balancing

This module supports the creation of a network passthrough load balancer for the deployed Workers. This should be enabled when these Workers will have downstream Workers connecting to the Workers deployed in this module. This is controlled by the variable `create_lb` which is defaulted to `false`

This load balancer is internal only and downstream workers should be connecting to upstream workers over private connectivity.

## Boundary Worker Tags

All tags in the `common_tags` variable will be applied to the Boundary Worker tags configuration. Additional tags to be added to the Worker config are controlled with the `worker_tags` variable.

## HCP Boundary

The Workers created with this module can be used with HCP Boundary. Please review the `hcp` example. Please review this documentation to retrieve the `Worker Auth Registration Request` needed for HCP Boundary. <https://developer.hashicorp.com/hcp/docs/boundary/self-managed-workers/install-self-managed-workers#start-the-self-managed-worker>


## Custom VM Image

If a custom VM image is preferred over using a standard marketplace image, the following variables may be set:

```hcl
vm_custom_image_name    = "<my-custom-ubuntu-2204-image>"
vm_custom_image_rg_name = "<my-custom-image-resource-group-name>"
```

## VM Disk Encryption Set

The following variables may be set to configure an existing Disk Encryption Set for the Boundary VMSS:

```hcl
vm_disk_encryption_set_name = <"my-disk-encryption-set-name">
vm_disk_encryption_set_rg   = <"my-disk-encryption-set-resource-group-name">
```

>📝 Note: ensure that your Key Vault that contains the key for the Disk Encryption Set has an Access Policy that allows the following key permissions: `Get`, `WrapKey`, and `UnwrapKey`.
