# Boundary Version Upgrades

See the [Boundary Releases](https://developer.hashicorp.com/boundary/docs/release-notes) page for full details on the releases. Because we have bootstrapped and automated the Boundary deployment, and our Boundary application data is decoupled from the VM(s), the VMs are stateless, ephemeral, and are treated as _immutable_. Therefore, the process of upgrading to a new Boundary version involves replacing/re-imaing the VMs within the Boundary Virtual Machine Scaleset (VMSS), rather than modifying the running VMs in-place. In other words, an upgrade effectively is a re-install of Boundary.

## Upgrade Procedure

This module includes an input variable named `boundary_version` that dicates which version of Boundary is deployed. Here are the steps to follow:

1. Determine your desired version of Boundary from the [Boundary Release Notes](https://developer.hashicorp.com/boundary/docs/release-notes) page. The value that you need will be in the **Version** column of the table that is displayed.

2. Update the value of the `boundary_version` input variable within your `terraform.tfvars` file.

```hcl
    boundary_version = "0.17.1+ent"
```

3. During a maintenance window, run `terraform apply` against your root Boundary worker configuration that manages your Boundary worker deployment.

4. Ensure that the VM(s) within the Boundary worker VMSS have been replaced/re-imaged with the changes. Monitor the cloud-init processes to ensure a successful re-install.
