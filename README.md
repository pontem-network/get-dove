# Get `dove` Action

This GitHub Action delivers specified [`dove`] release for a Move language.

[`dove`]: https://github.com/pontem-network/move-tools


## Parameters

- `version` - specified version of the release. Optional. Default value is `latest`.
- `token` - GITHUB_TOKEN. Optional.


## Usage Example

Download the latest version of dove

```yaml
- name: get dove
  uses: pontem-network/get-dove@main
```

Download a specific version of dove

```yaml
- name: get dove
  uses: pontem-network/get-dove@main
  with:
    version: 1.2.2
```

Download a specific version of dove and token

```yaml
- name: get dove
  uses: pontem-network/get-dove@main
  with:
    version: 1.2.0
    token: ${{ secrets.GITHUB_TOKEN }}
```
